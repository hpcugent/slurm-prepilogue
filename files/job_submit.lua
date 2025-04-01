function slurm_job_submit(job_desc, part_list, submit_uid)
    local min_mem_mb = 1000  -- Set minimum memory requirement in MB

    if job_desc.min_mem_per_node ~= nil and job_desc.min_mem_per_node < min_mem_mb then
        slurm.log_user("Error: Minimum memory per job is %d MB, please change your requirements.", min_mem_mb)
        return slurm.ERROR
    end

    return slurm.SUCCESS
end

function slurm_job_modify(job_desc, job_rec, part_list, modify_uid)
        return slurm.SUCCESS
end

slurm.log_info("job_submit.lua initialized")
return slurm.SUCCESS
