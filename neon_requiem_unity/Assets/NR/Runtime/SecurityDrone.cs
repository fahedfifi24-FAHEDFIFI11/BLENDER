using UnityEngine;
namespace NeonRequiem {
 public sealed class SecurityDrone : MonoBehaviour {
  public Vector3[] route;public Light searchLight;public Transform shell;
  public float Alert {get;private set;}
  public bool Disabled {get;private set;}
  int point;float shot,stun,clock;Vector3 basePosition;
  void Awake(){basePosition=transform.position;}
  void Update(){
   var g=Session.Instance;if(g==null||!g.Playing)return;
   if(g.rules.Stage<MissionStage.EvadeSecurity){if(searchLight)searchLight.enabled=false;return;}
   if(g.rules.Stage>=MissionStage.Extract){Disabled=true;if(searchLight)searchLight.enabled=false;return;}
   if(searchLight)searchLight.enabled=true;
   clock+=Time.deltaTime;shot-=Time.deltaTime;
   if(stun>0){stun-=Time.deltaTime;Alert=Mathf.MoveTowards(Alert,0,Time.deltaTime);if(shell)shell.localRotation=Quaternion.Euler(0,clock*160,12);return;}
   Vector3 target=g.player.transform.position+Vector3.up*(g.player.IsCrouched?.8f:1.45f);
   Vector3 delta=target-transform.position;bool see=false;
   if(delta.magnitude<(g.player.IsCrouched?10:17)&&Physics.Raycast(transform.position,delta,out var hit,18,(1<<8)|(1<<9),QueryTriggerInteraction.Ignore))see=hit.collider.GetComponentInParent<Operative>()!=null;
   Alert=Mathf.MoveTowards(Alert,see?1:0,Time.deltaTime*(see?.48f:.32f));
   if(searchLight){searchLight.color=Alert>.65f?new Color(1,.12f,.07f):new Color(1,.52f,.15f);searchLight.transform.rotation=Quaternion.LookRotation(see?delta:new Vector3(Mathf.Sin(clock*.8f),-.7f,1));}
   if(see&&Alert>.98f&&shot<=0){g.player.Damage(18);g.audioBus.OneShot("shot",transform.position,.5f);shot=1.5f;}
   if(route!=null&&route.Length>0){basePosition=Vector3.MoveTowards(basePosition,route[point],Time.deltaTime*(see?1.1f:1.9f));if(Vector3.Distance(basePosition,route[point])<.2f)point=(point+1)%route.Length;transform.position=basePosition+Vector3.up*Mathf.Sin(clock*2)*.08f;}
   if(shell)shell.localRotation=Quaternion.Euler(Mathf.Sin(clock)*4,clock*12,Mathf.Cos(clock)*3);
  }
  public bool Jam(Vector3 origin){if(Disabled||Vector3.Distance(origin,transform.position)>12||Session.Instance.rules.Stage!=MissionStage.EvadeSecurity)return false;stun=5;Alert=0;return true;}
 }
}
