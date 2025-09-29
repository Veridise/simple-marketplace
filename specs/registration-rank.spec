vars: Marketplace m, RegistrationDesk rd
spec: []!finished(rd.registerAsFreelancer, m.getFreelancerRank(sender) < 3)
