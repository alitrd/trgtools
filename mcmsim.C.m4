
Bool_t mcmsim(Int_t nEvents = -1)
{
  //  AliLog::SetClassDebugLevel("AliTRDmcmSim", 10);

  AliTRDtrapConfigHandler trapcfghandler;
  trapcfghandler.ResetMCMs();
  trapcfghandler.LoadConfig("trapcfg/initialize.r3610");
  trapcfghandler.LoadConfig("trapcfg/cf_p_zs-s16-deh_tb27_trkl-b5n-fs1e25-ht200-qs0e25s25e24-pidlhc10dv2-pt100_ptrg.r4676");

  ifelse(___TRACKLET_CONFIG___, `mc-tc', `
')

  ifelse(___TRACKLET_CONFIG___, `mc-notc', `
')

  ifelse(___TRACKLET_CONFIG___, `real-tc', `
')

  ifelse(___TRACKLET_CONFIG___, `real-notc', `
')


  AliRunLoader *rl = AliRunLoader::Open("galice.root");
  if (nEvents < 0)
    nEvents = rl->GetNumberOfEvents();

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
// 	  if (mcmsim->GetTrackletArray()->GetEntries() > 0)
// 	    mcmsim->Print("T");
	  mcmsim->StoreTracklets();
	}
      }
    }

    rl->GetLoader("TRDLoader")->GetDataLoader("tracklets")->WriteData("OVERWRITE");
    printf("processed event: %i\n", iEvent);

  }

  return kTRUE;
}
