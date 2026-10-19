using System;
using UnityEngine;
using UnityEngine.SceneManagement;
namespace NeonRequiem {
 public enum SessionMode { Title, Play, Pause, Dead, Ending, Complete }
 public sealed class Session : MonoBehaviour {
  public static Session Instance {get;private set;}
  public Operative player;public AudioBus audioBus;public SecurityDrone drone;public Presentation presentation;
  public Interactable[] stations;public Transform endingCamera;
  public MissionState rules=new MissionState();public SessionMode Mode {get;private set;}=SessionMode.Title;
  public bool Playing=>Mode==SessionMode.Play;public bool Hacking {get;private set;}
  public float Sensitivity=1.6f;public float PulseCooldown {get;private set;}
  public float PlayedSeconds {get;private set;}
  public string Message {get;private set;}
  public Interactable Focus {get;private set;}
  public int SelectedSymbol {get;private set;}
  int hackStartedFrame;float messageTimer,endingTime;Vector3 endingStart;Quaternion endingRotation;Interactable hackTarget;
  public event Action MissionChanged;
  void Awake(){Instance=this;rules.Changed+=OnChanged;}
  void Start(){Time.timeScale=0;CursorMode(true);Say("LOW TIDE DISTRICT / 04:17 / a city that remembers",8);}
  void OnDestroy(){rules.Changed-=OnChanged;if(Instance==this)Instance=null;Time.timeScale=1;}
  void OnChanged(){MissionChanged?.Invoke();}
  void CursorMode(bool visible){Cursor.visible=visible;Cursor.lockState=visible?CursorLockMode.None:CursorLockMode.Locked;}
  public void StartJourney(){Time.timeScale=1;Mode=SessionMode.Play;CursorMode(false);Say("Find MOTHER's listening booth in the west market. The city has a message for you.",10);}
  public void TogglePause(){if(Mode!=SessionMode.Play&&Mode!=SessionMode.Pause)return;if(Hacking){EndHack();return;}Mode=Mode==SessionMode.Pause?SessionMode.Play:SessionMode.Pause;Time.timeScale=Playing?1:0;CursorMode(!Playing);}
  public void Restart(){Time.timeScale=1;SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);}
  public void Die(){EndHack();Mode=SessionMode.Dead;Time.timeScale=0;CursorMode(true);}
  public void Say(string text,float seconds=6){Message=text;messageTimer=seconds;}
  void Update(){
   if(Mode==SessionMode.Pause&&Input.GetKeyDown(KeyCode.Escape)){TogglePause();return;}
   if(Mode==SessionMode.Ending){
    endingTime+=Time.unscaledDeltaTime;float t=Mathf.SmoothStep(0,1,endingTime/9);
    player.view.transform.position=Vector3.Lerp(endingStart,endingCamera.position,t);
    player.view.transform.rotation=Quaternion.Slerp(endingRotation,endingCamera.rotation,t);
    if(endingTime>=11){Mode=SessionMode.Complete;CursorMode(true);}return;
   }
   if(!Playing)return;
   PlayedSeconds+=Time.deltaTime;PulseCooldown=Mathf.Max(0,PulseCooldown-Time.deltaTime);
   messageTimer-=Time.deltaTime;if(messageTimer<=0)Message="";
   Focus=null;
   if(Physics.Raycast(player.view.transform.position,player.view.transform.forward,out var hit,3.1f,1<<8,QueryTriggerInteraction.Ignore))Focus=hit.collider.GetComponentInParent<Interactable>();
   if(Hacking&&Time.frameCount>hackStartedFrame){
    if(!hackTarget||Vector3.Distance(player.transform.position,hackTarget.transform.position)>3.5f){EndHack();return;}
    if(Input.GetKeyDown(KeyCode.A)||Input.GetKeyDown(KeyCode.LeftArrow))SelectedSymbol=(SelectedSymbol+3)%4;
    if(Input.GetKeyDown(KeyCode.D)||Input.GetKeyDown(KeyCode.RightArrow))SelectedSymbol=(SelectedSymbol+1)%4;
    if(Input.GetKeyDown(KeyCode.Return)||Input.GetKeyDown(KeyCode.E))SubmitSymbol();
   }
  }
  public void UseFocused(){if(Playing&&!Hacking&&Focus)Focus.Use();}
  public void BeginHack(Interactable source){hackTarget=source;hackStartedFrame=Time.frameCount;Hacking=true;SelectedSymbol=0;Say("Maintenance note: TRIANGLE / CIRCLE / CROSS. A–D to select; ENTER to submit; ESC to leave.",15);}
  public void EndHack(){Hacking=false;hackTarget=null;}
  public void SubmitSymbol(){
   if(!Hacking)return;bool correct=rules.Hack(SelectedSymbol);
   audioBus.OneShot(correct?"relay":"scan",player.transform.position,.5f);
   if(!correct)Say("Checksum rejected. Sequence cleared. The service placard contains the order.",6);
   if(rules.Stage==MissionStage.EvadeSecurity){EndHack();Say("SIGNAL FOUND. Security is awake. Break line of sight; Q jams a nearby drone for five seconds. Reach the override.",14);}
  }
  public void Pulse(){
   if(PulseCooldown>0)return;
   if(drone&&drone.Jam(player.transform.position)){PulseCooldown=12;audioBus.OneShot("scan",player.transform.position,.8f);Say("DRONE JAMMED / five seconds",4);}
   else Say("No active security drone within 12 metres.",3);
  }
  public void BeginEnding(){EndHack();Mode=SessionMode.Ending;endingTime=0;endingStart=player.view.transform.position;endingRotation=player.view.transform.rotation;Say("MOTHER / There you are. I can hear the rain again.",15);audioBus.OneShot("ending",player.transform.position,.7f);}
  public string Objective {
   get {switch(rules.Stage){
    case MissionStage.FindBroker:return "01 / Find MOTHER in the west listening market";
    case MissionStage.RestorePower:return "02 / Restore maintenance relays  "+rules.Relays.Count+" / 3";
    case MissionStage.DecodeSignal:return "03 / Decode the transmission in the listening room";
    case MissionStage.EvadeSecurity:return "04 / Evade the drone; reach the security override";
    case MissionStage.Extract:return "05 / Climb the amber stair; transmit from the skyline";
    default:return "GHOSTS IN THE RAIN / transmission delivered";
   }}
  }
  public Interactable Target(){
   if(stations==null)return null;Interactable best=null;float distance=float.MaxValue;
   foreach(var s in stations){if(!s)continue;bool match=
    (rules.Stage==MissionStage.FindBroker&&s.kind==InteractionKind.Broker)||
    (rules.Stage==MissionStage.RestorePower&&s.kind==InteractionKind.Relay&&!rules.Relays.Contains(s.id))||
    (rules.Stage==MissionStage.DecodeSignal&&s.kind==InteractionKind.Hack)||
    (rules.Stage==MissionStage.EvadeSecurity&&s.kind==InteractionKind.Override)||
    (rules.Stage==MissionStage.Extract&&s.kind==InteractionKind.Extraction);
    float d=Vector3.Distance(player.transform.position,s.transform.position);if(match&&d<distance){best=s;distance=d;}
   }return best;
  }
 }
}
