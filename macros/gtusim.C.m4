Bool_t gtusim(Int_t nEvents = ___NEVENTS___, Bool_t useFriends = kFALSE)
{
  // AliLog::SetClassDebugLevel("AliTRDgtuSim", 2);
  // AliLog::SetClassDebugLevel("AliTRDgtuTMU", 10);

  AliTRDfeeParam::SetTracklet(kTRUE);
  AliTRDgtuParam::SetDeltaY(18); // 9
  AliTRDgtuParam::SetDeltaAlpha(21); // 11
  AliTRDgtuParam::Instance()->SetVertexSize(10.);

  AliRunLoader *rl = AliRunLoader::Open("galice.root");

  TFile *esdFile = TFile::Open("AliESDs.root", "READ");
  TTree *esdTree = (TTree*) esdFile->Get("esdTree");

  AliESDEvent *esd = new AliESDEvent;
  // esd->CreateStdContent(kTRUE);
  // printf("found: %p, branch: %p\n", esd->FindListObject("AliESDfriend"), esdTree->GetBranch("ESDfriend."));
  esd->ReadFromTree(esdTree);
  TObject *friendObject = 0x0;
  if (useFriends) {
    friendObject = esd->FindListObject("AliESDfriend");
    if (friendObject) {
      esd->GetList()->Remove(friendObject);
    }
  }

  TFile *esdFileNew = TFile::Open("NewAliESDs.root", "RECREATE");
  TTree *esdTreeNew = new TTree(esdTree->GetName(), esdTree->GetTitle());
  esd->WriteToTree(esdTreeNew);
  if (useFriends)
    esd->AddObject(friendObject);
  esdTreeNew->GetUserInfo()->Add(esd);
  // printf("branch: %p\n", esdTreeNew->GetBranch("ESDfriend."));

  if (useFriends) {
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
  }

  if ((nEvents < 0) || (nEvents > esdTree->GetEntries()))
    nEvents = esdTree->GetEntries();

  AliLoader *trdLoader = rl->GetLoader("TRDLoader");
  AliDataLoader *trklLoader = trdLoader->GetDataLoader("tracklets");
  AliDataLoader *gtuLoader = trdLoader->GetDataLoader("gtutracks");
  if (!gtuLoader) {
    gtuLoader = new AliDataLoader("TRD.GtuTracks.root","gtutracks", "gtutracks");
    AliRunLoader::Instance()->GetLoader("TRDLoader")->AddDataLoader(gtuLoader);
  }

  AliTRDgtuSim *gtusim = new AliTRDgtuSim();

  for (Int_t iEvent = 0; iEvent < nEvents; iEvent++) {

    esdTree->GetEntry(iEvent);
    if (useFriends)
      esd->SetESDfriend(esdFriend);

    rl->GetEvent(iEvent);
    trklLoader->Load();

    // printf("#Tracks before sim: %i\n", esd->GetNumberOfTrdTracks());
    gtusim->RunGTU(0x0, esd, -2); // raw tracklets
    gtusim->RunGTU(0x0, esd, -1); // simulated tracklets
    // printf("#Tracks after sim: %i\n", esd->GetNumberOfTrdTracks());

    // for (Int_t iTrack = 0; iTrack < esd->GetNumberOfTrdTracks(); iTrack++) {
    //   AliESDTrdTrack *trk = esd->GetTrdTrack(iTrack);
    //   // printf("track %i: 0x%016llx, label: %i, PID: %i\n",
    //   //        iTrack, trk->GetTrackWord(), trk->GetLabel(), trk->GetPID());
    //   for (Int_t iLayer = 0; iLayer < 6; iLayer++) {
    //     AliESDTrdTracklet *trkl = trk->GetTracklet(iLayer);
    //     if (trkl)
    //       printf("layer %i: 0x%08x\n", iLayer, trkl->GetTrackletWord());
    //   }
    // }

    esdTreeNew->Fill();
    if (useFriends)
      esdFriendTreeNew->Fill();
    // gtusim->WriteTracksToLoader();

    if (gtuLoader)
      gtuLoader->WriteData("OVERWRITE");
    printf("processed event: %i\n", iEvent);

  }

  esdFileNew->cd();
  esdTreeNew->Write();
  esdFileNew->Close();

  if (useFriends) {
    esdFriendFileNew->cd();
    esdFriendTreeNew->Write();
    esdFriendFileNew->Close();
  }

  // gtusim->WriteTreesToFile();

  return kTRUE;
}
