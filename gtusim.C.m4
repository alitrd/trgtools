Bool_t gtusim(Int_t nEvents = -1) 
{
  // AliLog::SetClassDebugLevel("AliTRDgtuSim", 10);

  AliTRDfeeParam::SetTracklet(kTRUE);

  AliRunLoader *rl = AliRunLoader::Open("galice.root");

  TFile *esdFile = TFile::Open("AliESDs.root");
  TTree *esdTree = (TTree*) esdFile->Get("esdTree");
  AliESDEvent *esd = new AliESDEvent;
  esd->ReadFromTree(esdTree);

  TFile *esdFileNew = TFile::Open("AliESDNews.root", "RECREATE");
  esdFileNew->cd();
  TTree *esdTreeNew = new TTree("esdTree", "Tree with ESD objects"); 
  AliESDEvent * esdnew = new AliESDEvent;
  esdnew->CreateStdContent();
  esdnew->WriteToTree(esdTreeNew);

  if (nEvents < 0 && esdTree)
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
    rl->GetEvent(iEvent);
    trklLoader->Load();

    *esdnew = *esd;
    gtusim->RunGTU(trdLoader, esdnew);
    esdTreeNew->Fill();
    // gtusim->WriteTracksToLoader();

    if (gtuLoader)
      gtuLoader->WriteData("OVERWRITE");
    printf("processed event: %i\n", iEvent);

  }

  esdFileNew->cd();
  esdTreeNew->Write(esdTreeNew->GetName(), TObject::kOverwrite);
  esdFileNew->Close();

  gtusim->WriteTreesToFile();

  return kTRUE;
}
