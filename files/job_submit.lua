
-- config file for this script
-- This file does not need to exist, but if it exists, it needs to be valid lua
submit_filter_config_file = "/etc/slurm/submit_filter_conf.lua"

modules_dir = "/usr/libexec/slurm/lua_modules"
package.path = package.path .. ";" .. modules_dir.."/?.lua"
-- job_info = require("job_info")

function check_gpu_requested(job_desc)
    local tres_vals = {
        tres_per_job = job_desc.tres_per_job or false,
        tres_per_node = job_desc.tres_per_node or false,
        tres_per_socket = job_desc.tres_per_socket or false,
        tres_per_task = job_desc.tres_per_task or false
    }
    local gpu_requested = false

    for tres_name,tres_value in pairs(tres_vals) do
        if tres_value then
            if string.find(tres_value, "gpu:0") then
                return false
            end
            if string.find(tres_value, "gpu") then
                gpu_requested = true
            end
        end
    end
    return gpu_requested
end

function slurm_job_submit(job_desc, part_list, submit_uid)
    local min_mem_mb = 1000  -- Set minimum memory requirement in MB

    -- uncomment here and the require above to debug job info
    -- job_info._job_info(job_desc, part_list, submit_uid)

    if job_desc.min_mem_per_node ~= nil and job_desc.min_mem_per_node < min_mem_mb then
        slurm.log_user("Error: Minimum memory per job is %d MB, please change your requirements.", min_mem_mb)
        return slurm.ERROR
    end

    slurm_gpu_only_partitions = {}
    slurm_partition_cpus = {}

    -- try to read the configfile
    -- returns nil if the file doesn't exist
    conf, err = loadfile(submit_filter_config_file)

    if conf then
        -- run the file as lua code
        conf()

        part = job_desc.partition

        if not part then
            -- we can't get the default partition from slurm, so it must be set
            -- in the config file
            part = default_partition or ""
        end

        if slurm_partition_cpus[part] then
            -- Some nil values that are currently not handled correctly by
            -- slurm.
            -- If slurm is fixed later on, this code should still work.
            cpus_per_task = job_desc.cpus_per_task
            if cpus_per_task == 65534 then
                cpus_per_task = nil
            end
            min_nodes = job_desc.min_nodes
            if min_nodes == 4294967294 then
                min_nodes = nil
            end

            -- For each relevant partition, slurm_partition_cpus contains the
            -- number of CPUs on a node that is available by default.
            -- If the user asked more CPUs, we set core_spec to 0, to allow the
            -- job to use the special cores as well.
            -- If the user asked more CPUs than are available even when
            -- core_spec is set to 0, slurm will refuse the job, so we don't
            -- need to handle that case.
            if cpus_per_task ~= nil and cpus_per_task > slurm_partition_cpus[part] then
                slurm.log_info("setting core spec to 0: cpus_per_task %d", cpus_per_task)
                job_desc.core_spec = 0
            elseif min_nodes == nil then
                -- If the user didn't specify a number of nodes, only the
                -- number of cpus per task (checked above) is relevant, so we
                -- don't need further checks.
                --
                -- slurm.log_info("not setting core spec: min_nodes is null")
            else
                -- If the user specified a number of tasks and a number of
                -- nodes, we try to see if they fit. It seems min_cpus is set
                -- to the total requested in that case.
                -- Note that this does not cover all possible combinations, but
                -- if users want strange combinations, they should make sure
                -- they know what they're doing.
                if (job_desc.min_cpus / min_nodes) > slurm_partition_cpus[part] then
                    slurm.log_info("setting core spec to 0: min_cpus %d, min_nodes %d", job_desc.min_cpus, min_nodes)
                    job_desc.core_spec = 0
                else
                    -- slurm.log_info("not setting core spec: %d %d", job_desc.min_cpus, min_nodes)
                end
            end
        end

        -- example config entry:
        -- slurm_gpu_only_partitions["cubone_gpu"] = 1
        if slurm_gpu_only_partitions[part] then
             if not check_gpu_requested(job_desc) then
                slurm.log_user("Invalid GPU config specified for %s.", part)
                return slurm.ERROR
            end
        end
    end

    return slurm.SUCCESS
end

function slurm_job_modify(job_desc, job_rec, part_list, modify_uid)
        return slurm.SUCCESS
end

slurm.log_info("job_submit.lua initialized")
return slurm.SUCCESS
