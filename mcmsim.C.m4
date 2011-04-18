
Bool_t mcmsim(Int_t nEvents = 10) 
{
  //  AliLog::SetClassDebugLevel("AliTRDmcmSim", 10);

  AliTRDtrapConfigHandler trapcfghandler;
  AliTRDtrapConfig *trapcfg = AliTRDtrapConfig::Instance();
  trapcfghandler.LoadConfig();
  trapcfghandler.LoadConfig("demoLUT1D.datx");

  ifelse(___TRACKLET_CONFIG___, `mc-tc', `
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQS0,  2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQE0, 22);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQS1, 22);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQE1, 27);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFS,   2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFE,  22);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPVBY, 0);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPVT, 10);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPHT, 150);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFP,  28);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPCL,   2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPCT,  10);

  trapcfg->SetDmem(0xc025, 20 << 5); // 5 add. bin. digits from ndrift
')

  ifelse(___TRACKLET_CONFIG___, `mc-notc', `
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQS0,  2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQE0, 22);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQS1, 22);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQE1, 27);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFS,   2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFE,  22);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPVBY, 0);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPVT, 10);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPHT, 200);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFP,  40);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPCL,   2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPCT,  10);

  trapcfg->SetDmem(0xc025, 24 << 5); // 5 add. bin. digits from ndrift
')

  ifelse(___TRACKLET_CONFIG___, `real-tc', `
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQS0,  2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQE0, 22);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQS1, 22);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQE1, 27);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFS,   2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFE,  22);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPVBY, 0);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPVT, 10);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPHT, 150);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFP,  28);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPCL,   2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPCT,  10);

  trapcfg->SetDmem(0xc025, 20 << 5); // 5 add. bin. digits from ndrift
')

  ifelse(___TRACKLET_CONFIG___, `real-notc', `
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQS0,  2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQE0, 22);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQS1, 22);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPQE1, 27);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFS,   2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFE,  22);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPVBY, 0);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPVT, 10);

  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPHT, 200);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPFP,  40);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPCL,   2);
  trapcfg->SetTrapReg(AliTRDtrapConfig::kTPCT,  10);

  trapcfg->SetDmem(0xc025, 24 << 5); // 5 add. bin. digits from ndrift
')


  AliRunLoader *rl = AliRunLoader::Open("galice.root");

  AliTRDdigitsManager *digMgr = new AliTRDdigitsManager();
  AliTRDmcmSim *mcmsim = new AliTRDmcmSim();
  AliTRDmcmSim::SetApplyCut(kFALSE);

  for (Int_t iEvent = 0; iEvent < nEvents; iEvent++) {

    rl->GetEvent(iEvent);
    rl->LoadDigits("TRD");
    if (!rl->GetTreeD("TRD", kFALSE)) 
      continue;

    digMgr->ReadDigits(rl->GetTreeD("TRD", kFALSE));


    for (Int_t iDet = 0; iDet < 540; iDet++) {
      AliTRDarrayADC *digits = digMgr->GetDigits(iDet);
      if (!digits->HasData())
	continue;

      digits->Expand();

      for(Int_t iRob = 0; iRob < digits->GetNrow() / 2; iRob++) {
	for(Int_t iMcm = 0; iMcm < 16; iMcm++) {
	  mcmsim->Init(iDet, iRob, iMcm);
	  mcmsim->SetData(digits, 0x0);
	  mcmsim->Filter();
	  mcmsim->Tracklet();
	  if (mcmsim->GetTrackletArray()->GetEntries() > 0)
	    mcmsim->Print("T");
	  mcmsim->StoreTracklets();
	}
      }
    }

    rl->GetLoader("TRDLoader")->GetDataLoader("tracklets")->WriteData("OVERWRITE");
    printf("processed event: %i\n", iEvent);

  }

  return kTRUE;
}
