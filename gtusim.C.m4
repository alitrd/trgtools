Bool_t gtusim(Int_t nEvents = -1) 
{
  AliLog::SetClassDebugLevel("AliTRDgtuSim", 10);

  AliTRDfeeParam::SetTracklet(kTRUE);

  AliRunLoader *rl = AliRunLoader::Open("galice.root");
  if (nEvents < 0)
    nEvents = rl->GetNumberOfEvents();

  AliLoader *trdLoader = rl->GetLoader("TRDLoader");
  AliDataLoader *trklLoader = trdLoader->GetDataLoader("tracklets");
  AliDataLoader *gtuLoader = trdLoader->GetDataLoader("gtutracks");
  if (!gtuLoader) {
    //AliError("Could not get the gtutracks data loader, adding it now!");
    gtuLoader = new AliDataLoader("TRD.GtuTracks.root","gtutracks", "gtutracks");
    AliRunLoader::Instance()->GetLoader("TRDLoader")->AddDataLoader(gtuLoader);
  }

  AliTRDgtuSim *gtusim = new AliTRDgtuSim();

  for (Int_t iEvent = 0; iEvent < nEvents; iEvent++) {

    rl->GetEvent(iEvent);
    trklLoader->Load();

    gtusim->RunGTU(trdLoader);
    gtusim->WriteTracksToLoader();

    if (gtuLoader)
      gtuLoader->WriteData("OVERWRITE");
    printf("processed event: %i\n", iEvent);

  }

  gtusim->WriteTreesToFile();

  return kTRUE;
}
