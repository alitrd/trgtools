
void rec()
{
  AliCDBManager * man = AliCDBManager::Instance();
  man->SetDefaultStorage("___OCDB___");
  ___EXTRA___

  AliReconstruction rec;
  rec.SetEventRange(___STARTEVENT___, ___STARTEVENT___ + ___NEVENTS___);

  rec.SetRunReconstruction("___RECDETECTORS___");

  // QA options
  rec.SetRunQA(":") ;
  rec.SetQARefDefaultStorage("local://$ALICE_ROOT/QAref") ;

  // AliReconstruction settings
  rec.SetWriteESDfriend(kTRUE);
  rec.SetFractionFriends(1.); 
  rec.SetWriteAlignmentData();
  rec.SetInput(___INPUTFILE___);
  rec.SetOption("TRD", "___TRD_RECOPTIONS___"); 
  rec.SetUseTrackingErrorsForAlignment("ITS");
  rec.SetCleanESD(kFALSE);
  rec.SetStopOnError(kFALSE);

  AliLog::Flush();
  rec.Run();
}
