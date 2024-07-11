job "answers-that-work-pt-summary" {
  type = "batch"
  
  group "answers-that-work" {
    
    task "pt-summary" {
      driver = "raw_exec"
      
      meta{
        ptdest_dir = "/tmp/pt/collected/${attr.unique.hostname}"
      }
  
      template {
        data = <<-EOH
        	#!/bin/bash
          
          pt-summary > ${NOMAD_META_ptdest_dir}/pt-summary.out
        EOH
        destination = "local/pt-summary"
      }
      
      config {
        command = "local/pt-summary"
      }
    }
  }
}