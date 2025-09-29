vars: Marketplace m, address user
spec: []!finished(
            m.*, 
            m.isFreelancer(user) && 
            m.getRank(user) != 50 + m.getNoOfSuccessfulProjects(user) * 10
      )
