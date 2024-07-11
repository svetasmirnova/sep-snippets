job "answers-that-work-init" {
  type = "batch"
  
  group "answers-that-work" {
    
    task "create-ptdest" {
      driver = "raw_exec"

    meta{
      ptdest_dir = "local/pt/collected"
    }
  
      config {
        command = "mkdir"
        args = [
          "-p",
          "${NOMAD_META_ptdest_dir }/${attr.unique.hostname}/samples"
        ]
      }
    }
  }
}
