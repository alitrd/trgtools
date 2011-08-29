// -*-c++-*-
void sim(Int_t nev=___NEVENTS___) {
  
  AliSimulation simulator;
  simulator.SetMakeSDigits("TRD TOF PHOS HMPID EMCAL FMD ZDC PMD T0 VZERO");
  simulator.SetMakeDigitsFromHits("ITS TPC");
  simulator.SetMakeDigits("ITS TPC TRD TOF PHOS HMPID EMCAL FMD ZDC PMD T0 VZERO");

  simulator.SetDefaultStorage("local://$ALICE_ROOT/OCDB");
  simulator.SetSpecificStorage("GRP/GRP/Data",
			       Form("local://%s",gSystem->pwd()));
  simulator.SetSpecificStorage("TRD/Calib/TrapConfig", "local:///lustre/alice/jkl/ocdb");
  
  // no QA
  simulator.SetRunQA(":") ; 
  simulator.SetQARefDefaultStorage("local://$ALICE_ROOT/QAref") ;

  TStopwatch timer;
  timer.Start();
  simulator.Run(nev);
  timer.Stop();
  timer.Print();
}
