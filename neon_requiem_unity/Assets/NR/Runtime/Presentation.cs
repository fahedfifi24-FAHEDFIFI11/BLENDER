using System;
using System.IO;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
namespace NeonRequiem {
 public sealed class Presentation : MonoBehaviour {
  public Volume atmosphere;public Camera view;public ParticleSystem rain;
  public Light[] accentLights;
  int preset=1;float thunder;
  public string PresetName=>new[]{"MEDIUM","HIGH","ULTRA"}[preset];
  void Start(){preset=Mathf.Clamp(PlayerPrefs.GetInt("NR.graphics",1),0,2);Apply();Debug.Log("NR hardware: "+SystemInfo.graphicsDeviceName+"; ray-tracing capability reported="+SystemInfo.supportsRayTracing+". DXR mode is not enabled or validated in this delivery.");}
  public void Cycle(){preset=(preset+1)%3;PlayerPrefs.SetInt("NR.graphics",preset);PlayerPrefs.Save();Apply();}
  void Apply(){
   QualitySettings.vSyncCount=1;Application.targetFrameRate=60;
   QualitySettings.SetQualityLevel(preset,true);
   if(atmosphere){var p=atmosphere.profile;
    if(p.TryGet<ScreenSpaceReflection>(out var ssr))ssr.enabled.Override(preset>0);
    if(p.TryGet<GlobalIllumination>(out var gi))gi.enable.Override(preset==2);
    if(p.TryGet<Fog>(out var fog))fog.depthExtent.Override(preset==0?48:96);
   }
   if(rain){var em=rain.emission;em.rateOverTime=preset==0?450:preset==1?850:1200;}
   if(accentLights!=null)for(int i=0;i<accentLights.Length;i++)if(accentLights[i])accentLights[i].shadows=preset==0?LightShadows.None:LightShadows.Soft;
  }
  void Update(){
   var s=Session.Instance;if(!s)return;
   if(Input.GetKeyDown(KeyCode.F12)){
    string dir=Path.Combine(Application.persistentDataPath,"Screenshots");Directory.CreateDirectory(dir);
    string file=Path.Combine(dir,"NeonRequiem_"+DateTime.Now.ToString("yyyyMMdd_HHmmss")+".png");ScreenCapture.CaptureScreenshot(file);Debug.Log("Actual frame capture requested: "+file);
   }
   if(!s.Playing)return;
   thunder+=Time.deltaTime;if(thunder>43){thunder=0;s.audioBus.OneShot("thunder",s.player.transform.position,.35f);}
   if(rain){Vector3 p=s.player.transform.position;rain.transform.position=new Vector3(p.x,12,p.z);bool indoors=p.z>42&&p.z<76;var emission=rain.emission;emission.enabled=!indoors;}
  }
 }
}
