using UnityEngine;
namespace NeonRequiem {
 public sealed class RequiemHUD : MonoBehaviour {
  readonly Color ink=new Color(.74f,.87f,.88f),amber=new Color(1,.63f,.27f),panel=new Color(.025f,.045f,.06f,.94f);
  GUIStyle text,small,title,button;float sx,sy;
  void Styles(){if(text!=null)return;text=new GUIStyle(GUI.skin.label){fontSize=21,wordWrap=true};text.normal.textColor=ink;small=new GUIStyle(text){fontSize=16};title=new GUIStyle(text){fontSize=46};button=new GUIStyle(GUI.skin.button){fontSize=20};}
  void Box(Rect r,Color c){var previous=GUI.color;GUI.color=c;GUI.DrawTexture(r,Texture2D.whiteTexture);GUI.color=previous;}
  void Label(float x,float y,float w,float h,string value,GUIStyle style=null){GUI.Label(new Rect(x,y,w,h),value,style??text);}
  bool Button(float y,string label){return GUI.Button(new Rect(700,y,520,52),label,button);}
  void OnGUI(){
   var g=Session.Instance;if(!g||!g.player)return;Styles();sx=Screen.width/1920f;sy=Screen.height/1080f;var old=GUI.matrix;GUI.matrix=Matrix4x4.TRS(Vector3.zero,Quaternion.identity,new Vector3(sx,sy,1));
   if(g.Mode==SessionMode.Play){
    Box(new Rect(48,48,700,97),panel);Box(new Rect(48,48,3,97),amber);Label(70,62,650,70,g.Objective);
    Label(52,975,280,30,"INTEGRITY  "+Mathf.CeilToInt(g.player.Health)+"%",small);Box(new Rect(52,1015,250,4),new Color(.2f,.25f,.25f));Box(new Rect(52,1015,2.5f*g.player.Health,4),amber);
    Label(1410,986,460,40,g.PulseCooldown>0?"JAMMER / "+Mathf.CeilToInt(g.PulseCooldown)+"s":"Q / DRONE JAMMER READY",small);
    Box(new Rect(958,538,4,4),ink);
    if(g.Focus)Label(610,740,700,65,g.Focus.Prompt);
    var target=g.Target();if(target&&!g.Hacking){Vector3 screen=g.player.view.WorldToViewportPoint(target.transform.position+Vector3.up*1.8f);if(screen.z>0){float x=Mathf.Clamp(screen.x*1920,80,1740),y=Mathf.Clamp((1-screen.y)*1080,175,850);Label(x,y,170,32,"◇  "+Mathf.RoundToInt(Vector3.Distance(g.player.transform.position,target.transform.position))+" m",small);}}
    if(g.drone&&g.drone.Alert>.05f){Label(770,180,470,35,"SECURITY / BREAK LINE OF SIGHT",small);Box(new Rect(770,220,380*g.drone.Alert,4),new Color(1,.2f,.1f));}
    if(g.Hacking){
     Box(new Rect(540,300,840,390),panel);Label(580,330,760,50,"THE LISTENING MACHINE",title);Label(580,405,740,55,"Cipher fragments  "+g.rules.HackStep+" / 3");
     string[] symbols={"CIRCLE","SQUARE","TRIANGLE","CROSS"};for(int i=0;i<4;i++){Box(new Rect(580+i*190,480,175,65),i==g.SelectedSymbol?new Color(.15f,.34f,.36f):new Color(.05f,.09f,.11f));Label(593+i*190,499,170,35,symbols[i],small);}
     Label(580,590,750,75,"A / D  select    ENTER  submit    ESC  disconnect\nService order: TRIANGLE → CIRCLE → CROSS",small);
    }
   } else if(g.Mode!=SessionMode.Ending){
    Box(new Rect(0,0,1920,1080),new Color(.005f,.015f,.025f,.76f));Label(650,210,850,90,"N E O N   R E Q U I E M",title);Label(700,310,600,60,g.Mode==SessionMode.Title?"GHOSTS IN THE RAIN / an original district":g.Mode==SessionMode.Dead?"CONNECTION LOST":g.Mode==SessionMode.Complete?"TRANSMISSION DELIVERED":"SIGNAL PAUSED");
    if(g.Mode==SessionMode.Title){if(Button(410,"ENTER LOW TIDE DISTRICT"))g.StartJourney();}
    else if(g.Mode==SessionMode.Pause){if(Button(410,"RESUME"))g.TogglePause();}
    else {if(Button(410,"RESTART JOURNEY"))g.Restart();}
    if(Button(480,"GRAPHICS  /  "+g.presentation.PresetName))g.presentation.Cycle();
    if(Button(550,"AUDIO  /  "+Mathf.RoundToInt(g.audioBus.Volume*100)+"%"))g.audioBus.Volume=g.audioBus.Volume>=.99f?0:Mathf.Min(1,g.audioBus.Volume+.25f);
    Label(700,620,260,35,"MOUSE SENSITIVITY",small);g.Sensitivity=GUI.HorizontalSlider(new Rect(970,632,250,25),g.Sensitivity,.3f,3.5f);
    if(Button(685,"EXIT TO DESKTOP"))Application.Quit();
    Label(700,770,600,100,"WASD move · mouse look · SHIFT sprint · CTRL crouch\nE interact · Q jam drone · ESC pause\nF12 captures an actual gameplay screenshot",small);
    if(g.Mode==SessionMode.Complete)Label(700,890,650,70,"Recovered memories: "+g.rules.Memories.Count+" / 3   ·   Journey: "+Mathf.FloorToInt(g.PlayedSeconds/60)+"m "+Mathf.FloorToInt(g.PlayedSeconds%60)+"s",small);
   }
   if(!string.IsNullOrEmpty(g.Message)&&g.Mode!=SessionMode.Title){Box(new Rect(410,875,1100,77),panel);Label(435,885,1050,65,g.Message,small);}
   if(g.player.Hurt>0)Box(new Rect(0,0,1920,1080),new Color(.5f,.015f,.005f,g.player.Hurt*.12f));
   GUI.matrix=old;
  }
 }
}
