// -*-c++-*-
void sim(Int_t nev=___NEVENTS___) {

  AliTRDcalibDB::Instance()->SetTrapConfig("cf_p_zs-s16-deh_tb24_trkl-b5n-fs1e24-ht200-qs0e24s24e23-pidlinear-pt100_ptrg", "r4932");

  AliSimulation simulator;
  simulator.SetMakeSDigits("TRD TOF EMCAL VZERO");
  simulator.SetMakeDigitsFromHits("ITS TPC");
  simulator.SetMakeDigits("ITS TPC TRD TOF EMCAL VZERO");

  simulator.SetDefaultStorage("local://$ALICE_ROOT/OCDB");
  simulator.SetSpecificStorage("GRP/GRP/Data",
			       Form("local://%s",gSystem->pwd()));

  // no QA
  simulator.SetRunQA(":");
  simulator.SetQARefDefaultStorage("local://$ALICE_ROOT/QAref");

  TStopwatch timer;
  timer.Start();
  simulator.Run(nev);
  timer.Stop();
  timer.Print();
}
