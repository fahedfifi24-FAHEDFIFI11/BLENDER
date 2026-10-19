using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
namespace NeonRequiem {
 [RequireComponent(typeof(CharacterController))]
 public sealed class Operative : MonoBehaviour {
  public Camera view;
  CharacterController body;Vector3 horizontal;float vertical,pitch,stepTime,footCycle;bool crouched;
  public float Health {get;private set;}=100;
  public float Hurt {get;private set;}
  public bool IsCrouched=>crouched;
  public float Speed=>new Vector2(horizontal.x,horizontal.z).magnitude;
  void Awake(){body=GetComponent<CharacterController>();}
  void Update(){
   var g=Session.Instance;if(g==null)return;
   Hurt=Mathf.MoveTowards(Hurt,0,Time.unscaledDeltaTime*2);
   if(!g.Playing)return;
   if(Input.GetKeyDown(KeyCode.Escape)){g.TogglePause();return;}
   if(g.Hacking){horizontal=Vector3.zero;return;}
   transform.Rotate(0,Input.GetAxisRaw("Mouse X")*g.Sensitivity,0);
   pitch=Mathf.Clamp(pitch-Input.GetAxisRaw("Mouse Y")*g.Sensitivity,-82,82);
   bool wantsCrouch=Input.GetKey(KeyCode.LeftControl);
   if(wantsCrouch)crouched=true;
   else if(crouched){ // Clearance check prevents standing through ceiling geometry.
    Vector3 start=transform.position+Vector3.up*1.05f;
    if(!Physics.SphereCast(start,.26f,Vector3.up,out _, .7f,1<<8,QueryTriggerInteraction.Ignore))crouched=false;
   }
   body.height=Mathf.MoveTowards(body.height,crouched?1.1f:1.85f,Time.deltaTime*6);
   body.center=Vector3.up*body.height*.5f;
   Vector2 move=new Vector2((Input.GetKey(KeyCode.D)?1:0)-(Input.GetKey(KeyCode.A)?1:0),(Input.GetKey(KeyCode.W)?1:0)-(Input.GetKey(KeyCode.S)?1:0));
   move=Vector2.ClampMagnitude(move,1);
   float speed=crouched?1.7f:Input.GetKey(KeyCode.LeftShift)?5.2f:3.2f;
   Vector3 desired=(transform.right*move.x+transform.forward*move.y)*speed;
   horizontal=Vector3.MoveTowards(horizontal,desired,Time.deltaTime*14);
   if(body.isGrounded&&vertical<0)vertical=-2;
   if(body.isGrounded&&Input.GetKeyDown(KeyCode.Space)&&!crouched)vertical=4.3f;
   vertical-=15*Time.deltaTime;body.Move((horizontal+Vector3.up*vertical)*Time.deltaTime);
   if(transform.position.y< -12){Damage(200);return;}
   footCycle+=Time.deltaTime*Speed*2.5f;
   float bob=body.isGrounded?Mathf.Sin(footCycle)*.012f*Mathf.Min(Speed,3):0;
   view.transform.localPosition=Vector3.Lerp(view.transform.localPosition,new Vector3(0,body.height-.16f+bob,0),Time.deltaTime*14);
   view.transform.localRotation=Quaternion.Euler(pitch,0,0);
   view.fieldOfView=Mathf.Lerp(view.fieldOfView,speed>5&&Speed>4?77:73,Time.deltaTime*4);
   if(body.isGrounded&&Speed>.7f){stepTime+=Time.deltaTime*Speed;if(stepTime>1.65f){stepTime=0;g.audioBus.OneShot("step",transform.position,.24f);}}
   if(Input.GetKeyDown(KeyCode.E))g.UseFocused();
   if(Input.GetKeyDown(KeyCode.Q))g.Pulse();
  }
  public void Damage(float amount){if(Health<=0)return;Health=Mathf.Max(0,Health-amount);Hurt=1;Session.Instance.audioBus.OneShot("hurt",transform.position,.6f);if(Health==0)Session.Instance.Die();}
  public void Restore(Vector3 position){body.enabled=false;transform.position=position;transform.rotation=Quaternion.identity;body.enabled=true;Health=100;horizontal=Vector3.zero;vertical=0;pitch=0;crouched=false;}
 }
}
