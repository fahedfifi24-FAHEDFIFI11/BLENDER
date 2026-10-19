using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
namespace NeonRequiem.Editor {
 public static class SceneValidation {
  [MenuItem("Neon Requiem/Validate Generated Scene")]
  public static void Validate(){
   var sessions=UnityEngine.Object.FindObjectsByType<Session>(FindObjectsSortMode.None);
   Require(sessions.Length==1,"Exactly one Session is required");var s=sessions[0];
   Require(s.player&&s.player.view&&s.audioBus&&s.presentation&&s.drone&&s.endingCamera,"Session references missing");
   Require(s.stations.Length==10,"Expected 7 objective stations + 3 memories");
   var ids=new HashSet<string>();foreach(var station in s.stations){Require(station!=null&&ids.Add(station.id),"Missing/duplicate station");Require(station.GetComponentInChildren<Collider>()!=null,"Interaction has no collider: "+station.id);}
   foreach(string id in new[]{"mother","relay_a","relay_b","relay_c","cipher","security","extraction"})Require(ids.Contains(id),"Missing mission station: "+id);
   var gates=UnityEngine.Object.FindObjectsByType<LiftGate>(FindObjectsSortMode.None);Require(gates.Length==2,"Both mission gates required");
   Require(GraphicsSettings.defaultRenderPipeline is HDRenderPipelineAsset,"HDRP must be assigned");
   var pipeline=(HDRenderPipelineAsset)GraphicsSettings.defaultRenderPipeline;Require(pipeline.currentPlatformRenderPipelineSettings.supportSSR,"SSR support missing");
   Require(s.presentation.atmosphere.sharedProfile.Has<Fog>()&&s.presentation.atmosphere.sharedProfile.Has<ScreenSpaceReflection>(),"Atmosphere profile incomplete");
   foreach(var renderer in UnityEngine.Object.FindObjectsByType<MeshRenderer>(FindObjectsSortMode.None))foreach(var mat in renderer.sharedMaterials)Require(mat&&mat.shader&&mat.shader.name.StartsWith("HDRP/"),"Non-HDRP or missing material on "+renderer.name);
   Physics.SyncTransforms();
   // Route samples catch missing floor tiles/unit conversion, but cannot prove controller traversal.
   var samples=new List<Vector3>();for(int z=2;z<76;z+=3)samples.Add(new Vector3(0,1.6f,z));
   for(int x=-2;x>=-20;x-=2)samples.Add(new Vector3(x,1.6f,19));
   for(int z=78;z<=110;z+=2)samples.Add(new Vector3(0,(z<=100?(z-76)/3f:8)+1.6f,z));
   foreach(var p in samples)Require(Physics.Raycast(p,Vector3.down,2.1f,1<<8,QueryTriggerInteraction.Ignore),"No route floor at "+p);
   var floor=UnityEngine.Object.FindObjectsByType<MeshRenderer>(FindObjectsSortMode.None).FirstOrDefault(x=>x.transform.root.name.Contains("LOW TIDE")&&x.name.Contains("district_deck"));
   Require(floor!=null,"Authored deck meshes missing");
   Debug.Log("NR_SCENE_REFERENCE_CHECK_PASS. This is not an end-to-end playtest or visual-quality check.");
  }
  static void Require(bool value,string message){if(!value)throw new Exception("NEON REQUIEM validation: "+message);}
 }
}
