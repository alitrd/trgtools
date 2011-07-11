
Bool_t mcmsim(Int_t nEvents = -1)
{
  //  AliLog::SetClassDebugLevel("AliTRDmcmSim", 10);

  AliTRDtrapConfigHandler trapcfghandler;
  trapcfghandler.ResetMCMs();
  trapcfghandler.LoadConfig("/u/jklein/temp/init.dat");

  ifelse(___TRACKLET_CONFIG___, `mc-tc', `
  trapcfghandler.LoadConfig("/u/jklein/temp/cfg1806.dat");	
')

  ifelse(___TRACKLET_CONFIG___, `mc-notc', `
  trapcfghandler.LoadConfig("/u/jklein/temp/cfg1806.dat");	
')

  ifelse(___TRACKLET_CONFIG___, `real-tc', `
  trapcfghandler.LoadConfig("/u/jklein/temp/cfg1806.dat");	
')

  ifelse(___TRACKLET_CONFIG___, `real-notc', `
  trapcfghandler.LoadConfig("/u/jklein/temp/cfg1806.dat");	
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
