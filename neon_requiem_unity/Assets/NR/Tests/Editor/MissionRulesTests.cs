using NUnit.Framework;
namespace NeonRequiem.Tests {
 public sealed class MissionRulesTests {
  [Test] public void CannotExtractBeforeSecurity(){var m=new MissionState();Assert.IsFalse(m.Finish());Assert.IsFalse(m.SecurityOverride());Assert.AreEqual(MissionStage.FindBroker,m.Stage);}
  [Test] public void CannotPowerBeforeBroker(){var m=new MissionState();Assert.IsFalse(m.Power("relay_a"));Assert.AreEqual(0,m.Relays.Count);}
  [Test] public void DuplicateRelaysDoNotAdvance(){var m=new MissionState();m.Broker();Assert.IsTrue(m.Power("relay_a"));Assert.IsFalse(m.Power("relay_a"));Assert.IsFalse(m.Power("unknown"));Assert.AreEqual(1,m.Relays.Count);}
  [Test] public void AllThreeRelaysRequired(){var m=Powered();Assert.AreEqual(MissionStage.DecodeSignal,m.Stage);Assert.AreEqual(3,m.Relays.Count);}
  [Test] public void CipherCannotSkipPower(){var m=new MissionState();Assert.IsFalse(m.Hack(2));Assert.AreEqual(0,m.HackStep);}
  [Test] public void WrongSymbolResetsProgress(){var m=Powered();m.Hack(2);Assert.IsFalse(m.Hack(3));Assert.AreEqual(0,m.HackStep);Assert.AreEqual(1,m.FailedAttempts);}
  [Test] public void FullMissionCompletesInOrder(){var m=Powered();Assert.IsTrue(m.Hack(2));Assert.IsTrue(m.Hack(0));Assert.IsTrue(m.Hack(3));Assert.AreEqual(MissionStage.EvadeSecurity,m.Stage);Assert.IsFalse(m.Finish());Assert.IsTrue(m.SecurityOverride());Assert.IsTrue(m.Finish());Assert.AreEqual(MissionStage.Complete,m.Stage);}
  [Test] public void CompletedCipherCannotOverflow(){var m=Powered();m.Hack(2);m.Hack(0);m.Hack(3);Assert.IsFalse(m.Hack(3));Assert.AreEqual(3,m.HackStep);}
  [Test] public void DiscoveryIsIdempotentAndOptional(){var m=new MissionState();Assert.IsTrue(m.Discover("memory_market"));Assert.IsFalse(m.Discover("memory_market"));Assert.AreEqual(MissionStage.FindBroker,m.Stage);}
  [Test] public void NewSessionResetsProgress(){var old=Powered();var fresh=new MissionState();Assert.AreEqual(0,fresh.Relays.Count);Assert.AreEqual(MissionStage.FindBroker,fresh.Stage);}
  [Test] public void ChangeSignalEmittedOnlyForValidTransitions(){var m=new MissionState();int count=0;m.Changed+=()=>count++;m.Finish();m.Broker();m.Broker();m.Power("relay_a");m.Power("relay_a");Assert.AreEqual(2,count);}
  static MissionState Powered(){var m=new MissionState();m.Broker();m.Power("relay_a");m.Power("relay_b");m.Power("relay_c");return m;}
 }
}
