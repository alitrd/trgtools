// -*-c++-*-
void sim(Int_t nev=___NEVENTS___) {
  
  AliTRDtrapConfigHandler trapConfigHandler;
  trapConfigHandler.LoadConfig("trapcfg/initialize.r3610");
  trapConfigHandler.LoadConfig("trapcfg/cf_p_zs-s16-deh_tb27_trkl-b5p-fs1e25-ht200-qs0e25s25e24-pidlhc10dv2-pt100_ptrg.r4660");

  AliSimulation simulator;
  simulator.SetMakeSDigits("TRD TOF PHOS HMPID EMCAL MUON FMD ZDC PMD T0 VZERO");
  simulator.SetMakeDigitsFromHits("ITS TPC");

  simulator.SetDefaultStorage("local://$ALICE_ROOT/OCDB");
  simulator.SetSpecificStorage("GRP/GRP/Data",
			       Form("local://%s",gSystem->pwd()));
  
  // no QA
  simulator.SetRunQA(":") ; 
  simulator.SetQARefDefaultStorage("local://$ALICE_ROOT/QAref") ;

  TStopwatch timer;
  timer.Start();
  simulator.Run(nev);
  timer.Stop();
  timer.Print();
}
