
-- config file for this script
-- This file does not need to exist, but if it exists, it needs to be valid lua
submit_filter_config_file = "/etc/slurm/submit_filter_conf.lua"

function slurm_job_submit(job_desc, part_list, submit_uid)
    local min_mem_mb = 1000  -- Set minimum memory requirement in MB

    if job_desc.min_mem_per_node ~= nil and job_desc.min_mem_per_node < min_mem_mb then
        slurm.log_user("Error: Minimum memory per job is %d MB, please change your requirements.", min_mem_mb)
        return slurm.ERROR
    end

    slurm_gpu_only_partitions = {}

    -- try to read the configfile
    -- returns nil of the file doesn't exist
    conf, err = loadfile(submit_filter_config_file)

    if conf then
        -- run the file as lua code
        conf()

        -- example config entry:
        -- slurm_gpu_only_partitions["cubone_gpu"] = 1
        if slurm_gpu_only_partitions[job_desc.partition] then
             tres = job_desc.tres_per_node or ""
             if not string.match(tres, "gpu") then
                slurm.log_user("Invalid GPU config specified for %s.", job_desc.partition)
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
