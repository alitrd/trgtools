Bool_t mcmsim(Int_t nEvents = ___NEVENTS___)
{
  // AliLog::SetClassDebugLevel("AliTRDrawStream", 10);

  AliCDBManager::Instance()->SetDefaultStorage("local:///hera/alice/alien/alice/data/2013/OCDB");
  AliCDBManager::Instance()->SetSpecificStorage("TRD/Calib/TrapConfig", "local:///hera/alice/jklein/ocdb");
  AliCDBManager::Instance()->SetRun(0);

  // AliTRDcalibDB::Instance()->SetTrapConfig("cf_pg-fpnp32_zs-s16-deh_tb22_trkl-b5n-fs1e24-ht200-qs0e23s23e22-pidlhc11dv1-pt100_ptrg", "r5037");
  AliTRDcalibDB::Instance()->SetTrapConfig("cf_p_zs-s16-deh_tb24_trkl-b5p-fs1e24-ht200-qs0e24s24e23-pidlinear-pt100_ptrg", "r4866");

  for (Int_t iDet = 0; iDet < 540; ++iDet) {
    AliTRDcalibDB::Instance()->GetTrapConfig()->SetTrapReg(AliTRDtrapConfig::kFPBY, 0, iDet);
    AliTRDcalibDB::Instance()->GetTrapConfig()->SetTrapReg(AliTRDtrapConfig::kFGBY, 0, iDet);
    AliTRDcalibDB::Instance()->GetTrapConfig()->SetTrapReg(AliTRDtrapConfig::kFTBY, 0, iDet);
  }

  AliTRDtrapConfigHandler trapcfghandler(AliTRDcalibDB::Instance()->GetTrapConfig());
  // trapcfghandler.ResetMCMs();
  // trapcfghandler.LoadConfig("trapcfg/initialize.r3610");
  // trapcfghandler.LoadConfig("trapcfg/cf_p_zs-s16-deh_tb27_trkl-b5n-fs1e25-ht200-qs0e25s25e24-pidlhc10dv2-pt100_ptrg.r4676");

  ifelse(___TRACKLET_CONFIG___, `mc-tc', `')
  ifelse(___TRACKLET_CONFIG___, `mc-notc', `')
  ifelse(___TRACKLET_CONFIG___, `real-tc', `')
  ifelse(___TRACKLET_CONFIG___, `real-notc', `')

  AliRunLoader *rl = AliRunLoader::Open("galice.root");
  if (nEvents < 0 || nEvents > rl->GetNumberOfEvents())
    nEvents = rl->GetNumberOfEvents();

  if(nEvents==0) {
     std::cerr << "ERROR: No events in galice.root found. Aborting ..." << std::endl;
     return kFALSE;
  }

  AliTRDdigitsManager *digMgr = new AliTRDdigitsManager();
  AliTRDmcmSim::SetStoreClusters(kTRUE);
  AliTRDmcmSim *mcmsim = new AliTRDmcmSim();

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

      for (Int_t iSide = 0; iSide <= 1; iSide++) {
	for(Int_t iRob = iSide; iRob < digits->GetNrow() / 2; iRob += 2) {
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
    }

    AliLoader *trdLoader = rl->GetLoader("TRDLoader");
    if (trdLoader)
      trdLoader->GetDataLoader("tracklets")->WriteData("OVERWRITE");
    else
      printf("no TRD loader\n");
    printf("processed event: %i\n", iEvent);

  }

  // now write the ESDs
  TFile *esdFile = TFile::Open("AliESDs.root", "READ");
  TTree *esdTree = (TTree*) esdFile->Get("esdTree");

  AliESDEvent *esd = new AliESDEvent;
  esd->ReadFromTree(esdTree);
  TObject *friendObject = esd->FindListObject("AliESDfriend");
  if (friendObject) {
    esd->GetList()->Remove(friendObject);
  }

  TFile *esdFileNew = TFile::Open("NewAliESDs.root", "RECREATE");
  TTree *esdTreeNew = new TTree(esdTree->GetName(), esdTree->GetTitle());
  esd->WriteToTree(esdTreeNew);
  esd->AddObject(friendObject);
  esdTreeNew->GetUserInfo()->Add(esd);

  esdTree->AddFriend("esdFriendTree", "AliESDfriends.root");
  esdTree->SetBranchStatus("ESDfriend.", 1);
  AliESDfriend *esdFriend = new AliESDfriend;
  esd->SetESDfriend(esdFriend);
  if (esdFriend)
    esdTree->SetBranchAddress("ESDfriend.", &esdFriend);

  TFile *esdFriendFileNew = TFile::Open("NewAliESDfriends.root", "RECREATE");
  TTree *esdFriendTreeNew = new TTree("esdFriendTree", "Tree with ESD Friend objects");
  if (esdFriend)
    esdFriendTreeNew->Branch("ESDfriend.", "AliESDfriend", &esdFriend);

  if (nEvents < 0 && esdTree)
    nEvents = esdTree->GetEntries();

  for (Int_t iEvent = 0; iEvent < nEvents; iEvent++) {

    esdTree->GetEntry(iEvent);
    esd->SetESDfriend(esdFriend);

    rl->GetEvent(iEvent);

    // read the simulated tracklets
    AliLoader* loader = rl->GetLoader("TRDLoader");

    TClonesArray *trklArray = new TClonesArray("AliTRDtrackletMCM");

    AliDataLoader *trackletLoader = loader->GetDataLoader("tracklets");
    if (trackletLoader) {
      // simulated tracklets                                                                                                                   
      trackletLoader->Load();
      TTree *trackletTree = trackletLoader->Tree();

      if (trackletTree) {
	TBranch *trklbranch = trackletTree->GetBranch("mcmtrklbranch");
	if (trklbranch && trklArray) {
	  AliTRDtrackletMCM *trkl = 0x0;
	  trklbranch->SetAddress(&trkl);
	  for (Int_t iTracklet = 0; iTracklet < trklbranch->GetEntries(); iTracklet++) {
	    trklbranch->GetEntry(iTracklet);
	    new ((*trklArray)[trklArray->GetEntries()]) AliTRDtrackletMCM(*trkl);
	  }
	}
      }
    }

    TList sortedTracklets;
    Int_t indices[1080] = { 0 };
    AliTRDrawStream::SortTracklets(trklArray, sortedTracklets, indices);

    TIter trackletIter(&sortedTracklets);
    AliTRDtrackletMCM *tracklet = 0x0;
    while (tracklet = (AliTRDtrackletMCM*) trackletIter()) {
      Int_t label = -1;
      esd->AddTrdTracklet(new AliESDTrdTracklet(tracklet->GetTrackletWord(), tracklet->GetHCId(), label));
    }

    esdTreeNew->Fill();
    esdFriendTreeNew->Fill();

    printf("processed event: %i\n", iEvent);
  }

  esdFileNew->cd();
  esdTreeNew->Write();
  esdFileNew->Close();

  esdFriendFileNew->cd();
  esdFriendTreeNew->Write();
  esdFriendFileNew->Close();
}
