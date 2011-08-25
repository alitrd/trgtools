// -*-c++-*-
void sim(Int_t nev=___NEVENTS___) {
  
  AliTRDfeeParam::SetTracklet(kTRUE);

  AliTRDtrapConfigHandler trapConfigHandler(AliTRDcalibDB::Instance()->GetTrapConfig());
  trapConfigHandler.ResetMCMs();
  trapConfigHandler.LoadConfig("trapcfg/initialize.r3610");
  trapConfigHandler.LoadConfig("trapcfg/cf_p_zs-s16-deh_tb27_trkl-b5n-fs1e25-ht200-qs0e25s25e24-pidlhc10dv2-pt100_ptrg.r4676");

  AliSimulation simulator;
  simulator.SetMakeSDigits("TRD TOF PHOS HMPID EMCAL FMD ZDC PMD T0 VZERO");
  simulator.SetMakeDigitsFromHits("ITS TPC");
  simulator.SetMakeDigits("ITS TPC TRD TOF PHOS HMPID EMCAL FMD ZDC PMD T0 VZERO");

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
