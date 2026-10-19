using UnityEngine;
namespace NeonRequiem {
 public sealed class AudioBus : MonoBehaviour {
  public AudioSource rain,score,vent;public float Volume=.65f;
  public void OneShot(string name,Vector3 pos,float gain){var clip=Resources.Load<AudioClip>("NR/Audio/"+name);if(!clip)return;var o=new GameObject("Transient audio");o.transform.position=pos;var a=o.AddComponent<AudioSource>();a.clip=clip;a.spatialBlend=.65f;a.minDistance=2;a.maxDistance=25;a.volume=gain*Volume;a.Play();Destroy(o,clip.length+.1f);}
  void Update(){
   var s=Session.Instance;if(!s||!s.player)return;float z=s.player.transform.position.z;bool interior=z>42&&z<76;
   if(rain)rain.volume=Mathf.Lerp(rain.volume,(interior?.08f:.45f)*Volume,Time.unscaledDeltaTime*2);
   if(score)score.volume=.23f*Volume;
   if(vent)vent.volume=Mathf.Lerp(vent.volume,(interior?.4f:.05f)*Volume,Time.unscaledDeltaTime*2);
  }
 }
}
