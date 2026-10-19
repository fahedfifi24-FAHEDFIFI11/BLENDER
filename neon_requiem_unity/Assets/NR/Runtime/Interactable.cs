using UnityEngine;
namespace NeonRequiem {
 public enum InteractionKind { Broker, Relay, Hack, Override, Extraction, Memory }
 public sealed class Interactable : MonoBehaviour {
  public InteractionKind kind;public string id;public string caption;[TextArea]public string story;
  public string Prompt {
   get {
    var m=Session.Instance.rules;
    switch(kind){
     case InteractionKind.Broker:return m.Stage==MissionStage.FindBroker?"E  /  LISTEN TO THE BROKER":"Signal routed. Follow the amber service line.";
     case InteractionKind.Relay:return m.Relays.Contains(id)?"RELAY ONLINE":m.Stage==MissionStage.RestorePower?"E  /  RESTORE RELAY":"Requires broker cipher";
     case InteractionKind.Hack:return m.Stage==MissionStage.DecodeSignal?"E  /  DECODE THE GHOST SIGNAL":m.Stage<MissionStage.DecodeSignal?"Restore all three relays first":"Transmission recovered";
     case InteractionKind.Override:return m.Stage==MissionStage.EvadeSecurity?"E  /  DISABLE SECURITY & UNLOCK ASCENT":"Security override";
     case InteractionKind.Extraction:return m.Stage==MissionStage.Extract?"E  /  TRANSMIT TO THE SKYLINE":"Extraction requires security clearance";
     default:return "E  /  "+caption;
    }
   }
  }
  public void Use(){
   var s=Session.Instance;bool changed=false;
   switch(kind){
    case InteractionKind.Broker:changed=s.rules.Broker();if(changed)s.Say("MOTHER / They sold our voices to the weather network. Bring them back. Three relays. Then the listening room.",12);break;
    case InteractionKind.Relay:changed=s.rules.Power(id);if(changed)s.Say("Relay restored. "+s.rules.Relays.Count+" / 3",4);break;
    case InteractionKind.Hack:if(s.rules.Stage==MissionStage.DecodeSignal)s.BeginHack(this);break;
    case InteractionKind.Override:changed=s.rules.SecurityOverride();if(changed)s.Say("Security blinded. The skyline stair is open. Keep moving.",8);break;
    case InteractionKind.Extraction:changed=s.rules.Finish();if(changed)s.BeginEnding();break;
    case InteractionKind.Memory:changed=s.rules.Discover(id);s.Say(story,12);break;
   }
   if(changed)s.audioBus.OneShot("relay",transform.position,.6f);
  }
 }
}
