using System;
using System.Collections.Generic;
namespace NeonRequiem {
 public enum MissionStage { FindBroker, RestorePower, DecodeSignal, EvadeSecurity, Extract, Complete }
 // Engine-independent rules: UI, input and colliders cannot advance stages out of order.
 public sealed class MissionState {
  public MissionStage Stage { get; private set; } = MissionStage.FindBroker;
  public readonly HashSet<string> Relays = new HashSet<string>();
  public readonly HashSet<string> Memories = new HashSet<string>();
  public int HackStep { get; private set; }
  public int FailedAttempts { get; private set; }
  public event Action Changed;
  public bool Broker() { if(Stage!=MissionStage.FindBroker)return false; Stage=MissionStage.RestorePower;Changed?.Invoke();return true; }
  public bool Power(string id) {
   if(Stage!=MissionStage.RestorePower || (id!="relay_a"&&id!="relay_b"&&id!="relay_c") || !Relays.Add(id))return false;
   if(Relays.Count==3)Stage=MissionStage.DecodeSignal;Changed?.Invoke();return true;
  }
  // A deterministic three-symbol cipher, exposed on the adjacent maintenance placard.
  public bool Hack(int symbol) {
   if(Stage!=MissionStage.DecodeSignal)return false;
   int[] code={2,0,3};
   if(symbol!=code[HackStep]){HackStep=0;FailedAttempts++;Changed?.Invoke();return false;}
   HackStep++;if(HackStep==3)Stage=MissionStage.EvadeSecurity;Changed?.Invoke();return true;
  }
  public bool SecurityOverride(){if(Stage!=MissionStage.EvadeSecurity)return false;Stage=MissionStage.Extract;Changed?.Invoke();return true;}
  public bool Finish(){if(Stage!=MissionStage.Extract)return false;Stage=MissionStage.Complete;Changed?.Invoke();return true;}
  public bool Discover(string id){if(!Memories.Add(id))return false;Changed?.Invoke();return true;}
 }
}
