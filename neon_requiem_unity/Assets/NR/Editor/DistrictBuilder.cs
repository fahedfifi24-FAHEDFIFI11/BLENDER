using System;
using System.IO;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.SceneManagement;
namespace NeonRequiem.Editor {
 public static class DistrictBuilder {
  static Transform root;static readonly List<Interactable> stations=new List<Interactable>();static readonly List<Light> shadowLights=new List<Light>();
  static readonly Color amber=new Color(1,.49f,.2f),ice=new Color(.24f,.63f,.72f),violet=new Color(.58f,.36f,.7f);
  [MenuItem("Neon Requiem/Generate District")]
  public static void Generate(){
   if(!Application.unityVersion.StartsWith("6000.0."))throw new Exception("Target editor is Unity 6000.0 LTS; validate API upgrades before changing series.");
   if(!Application.isBatchMode&&!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())return;
   ArtPipeline.Configure();stations.Clear();shadowLights.Clear();
   var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);root=new GameObject("LOW TIDE / authored district").transform;
   GroundAndMarket();Undercity();Skyline();Steam(new Vector3(-3.5f,.6f,56));Steam(new Vector3(4.5f,.3f,25));
   var session=new GameObject("Mission / Ghosts in the Rain").AddComponent<Session>();session.gameObject.AddComponent<RequiemHUD>();
   var person=new GameObject("Courier / first person");person.layer=9;person.transform.position=new Vector3(0,.1f,1);
   var controller=person.AddComponent<CharacterController>();controller.height=1.85f;controller.radius=.28f;controller.center=Vector3.up*.925f;controller.stepOffset=.28f;controller.slopeLimit=48;controller.skinWidth=.035f;
   var player=person.AddComponent<Operative>();var cameraGO=new GameObject("Courier camera");cameraGO.tag="MainCamera";cameraGO.transform.SetParent(person.transform,false);cameraGO.transform.localPosition=Vector3.up*1.69f;
   player.view=cameraGO.AddComponent<Camera>();player.view.nearClipPlane=.06f;player.view.farClipPlane=450;player.view.fieldOfView=73;cameraGO.AddComponent<AudioListener>();
   var hd=cameraGO.AddComponent<HDAdditionalCameraData>();hd.antialiasing=HDAdditionalCameraData.AntialiasingMode.TemporalAntialiasing;hd.customRenderingSettings=true;
   foreach(var field in new[]{FrameSettingsField.SSR,FrameSettingsField.SSAO,FrameSettingsField.SSGI,FrameSettingsField.Volumetrics}){hd.renderingPathCustomFrameSettings.SetEnabled(field,true);hd.renderingPathCustomFrameSettingsOverrideMask.mask[(uint)field]=true;}
   session.player=player;session.stations=stations.ToArray();
   var volumeGO=new GameObject("Atmosphere / cool rain and warm practicals");var volume=volumeGO.AddComponent<Volume>();volume.isGlobal=true;volume.sharedProfile=ArtPipeline.volume;
   session.presentation=session.gameObject.AddComponent<Presentation>();session.presentation.view=player.view;session.presentation.atmosphere=volume;session.presentation.accentLights=shadowLights.ToArray();session.presentation.rain=Rain();
   session.audioBus=session.gameObject.AddComponent<AudioBus>();session.audioBus.rain=Loop("rain",.25f);session.audioBus.score=Loop("night",.18f);session.audioBus.vent=Loop("vent",.04f);
   var droneRoot=new GameObject("SECURITY / active after decoding");droneRoot.transform.position=new Vector3(0,2.7f,64);var drone=droneRoot.AddComponent<SecurityDrone>();var model=Asset("drone",droneRoot.transform.position,0,Vector3.one*.65f,false);model.transform.SetParent(droneRoot.transform,true);drone.shell=model.transform;
   drone.route=new[]{new Vector3(-2,2.7f,61),new Vector3(2,2.7f,68),new Vector3(-1,2.7f,73)};drone.searchLight=Light("Security search cone",new Vector3(0,2.7f,64),amber,2200,15,true,true);drone.searchLight.spotAngle=48;drone.searchLight.transform.SetParent(droneRoot.transform,true);session.drone=drone;
   var ending=new GameObject("Cinematic / horizon composition");ending.transform.position=new Vector3(1,10,106);ending.transform.rotation=Quaternion.Euler(-8,8,0);session.endingCamera=ending.transform;
   var moon=Light("Blue-hour moon",new Vector3(0,35,20),new Color(.36f,.48f,.66f),1.5f,300,true);moon.type=LightType.Directional;moon.intensity=1.5f;moon.transform.rotation=Quaternion.Euler(28,-32,0);
   Probe("Market reflection",new Vector3(0,3,20),new Vector3(20,9,40));Probe("Service reflection",new Vector3(0,2.5f,58),new Vector3(9,6,30));Probe("Skyline reflection",new Vector3(0,10,105),new Vector3(20,10,20));
   Directory.CreateDirectory("Assets/NR/Scenes");EditorSceneManager.SaveScene(scene,"Assets/NR/Scenes/LowTide.unity");EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene("Assets/NR/Scenes/LowTide.unity",true)};
   AssetDatabase.SaveAssets();AssetDatabase.Refresh();SceneValidation.Validate();
   File.WriteAllText("Validation/UNITY_IMPORT_RECEIPT.json","{\"editor\":\""+Application.unityVersion+"\",\"scene\":\"LowTide\",\"generated\":true,\"playtested\":false}");Debug.Log("NEON_REQUIEM_SCENE_GENERATED. Gameplay and GPU visual review still required.");
  }
  static void GroundAndMarket(){
   // Primary route: long sightline toward the service arch, with a westward warm market pocket.
   for(int z=3;z<=39;z+=6){Asset("district_deck",new Vector3(-3,0,z),0,new Vector3(.75f,1,1));Asset("district_deck",new Vector3(3,0,z),0,new Vector3(.75f,1,1));}
   for(int z=3;z<=39;z+=6)for(int side=-1;side<=1;side+=2){
    if(side<0&&(z==15||z==21))continue;
    var facade=Asset("facade",new Vector3(side*9,0,z),side<0?90:-90,Vector3.one);
    if(z%12==3){Asset("hvac",new Vector3(side*6.7f,3.2f,z+1),side<0?90:-90,Vector3.one*.6f);Light("Shop practical",new Vector3(side*5.3f,2.5f,z),side<0?amber:ice,90,7,z==9||z==33);}
    Asset("pipe_bank",new Vector3(side*6.5f,0,z-2),side<0?90:-90,Vector3.one*.65f);
   }
   for(int z=9;z<=33;z+=12){Asset("cables",new Vector3(0,7,z),0,new Vector3(1.4f,1,1));Asset("skybridge",new Vector3(0,8,z+2),0,Vector3.one);}
   Sign("market",new Vector3(0,5.5f,10),0,5.5f);Sign("noodles",new Vector3(5.8f,2.6f,13),90,3.6f);Sign("corporate",new Vector3(-5.8f,7,32),-90,4);
   Asset("signal_emblem",new Vector3(5.6f,4,23),-90,Vector3.one*.8f,false).AddComponent<AmbientMotion>().rotationSpeed=new Vector3(0,0,8);
   for(int x=-9;x>=-21;x-=6)for(int z=15;z<=21;z+=6)Asset("district_deck",new Vector3(x,0,z),0,new Vector3(.75f,1,1));
   for(int i=0;i<3;i++){float x=-11-i*4;Asset("stall",new Vector3(x,0,13),0,Vector3.one);Asset("canopy",new Vector3(x,3.5f,13),0,Vector3.one*.7f);Asset("crate",new Vector3(x-1.4f,0,15.2f),14,Vector3.one*.65f);Light("Market counter",new Vector3(x,2.1f,15),amber,65,6,i==1);}
   Asset("facade",new Vector3(-25,0,18),90,new Vector3(2,1,1));Solid("Market rear",new Vector3(-24,2.5f,18),new Vector3(.5f,5,13));
   Solid("Market north edge",new Vector3(-17,2.5f,24),new Vector3(18,5,.5f));Solid("Market south edge",new Vector3(-17,2.5f,12),new Vector3(18,5,.5f));
   Asset("service_arch",new Vector3(-17,0,23),0,Vector3.one);Sign("mother",new Vector3(-18,3,22.5f),0,4.8f);
   Station(InteractionKind.Broker,"mother",new Vector3(-18,0,21),180,"LISTEN","MOTHER speaks through a salvaged listening machine.");
   Station(InteractionKind.Memory,"memory_market",new Vector3(-11,0,22),180,"READ THE WALL","A rent notice dated nine years ago. Someone has crossed out EVICTION and written: STILL HERE.");
   Station(InteractionKind.Memory,"memory_street",new Vector3(4.5f,0,30),-90,"READ A LOST VOICE","Recorded message / If the rain stops, leave the kitchen light on. I will find my way home.");
   for(int i=0;i<5;i++){Asset("crate",new Vector3(i%2==0?-4.7f:4.7f,0,8+i*6),i*13,Vector3.one*.8f);}
   Asset("service_arch",new Vector3(0,0,41),0,new Vector3(1.25f,1.2f,1));Sign("undercity",new Vector3(0,4,40.8f),0,5);
   Gate(new Vector3(0,0,42),MissionStage.RestorePower);
   Solid("Street arrival boundary",new Vector3(0,2.5f,-1),new Vector3(14,5,.5f));Asset("security_grille",new Vector3(0,0,-1),0,new Vector3(3.4f,1,1));
  }
  static void Undercity(){
   for(int z=45;z<=75;z+=6){
    Asset("district_deck",new Vector3(0,0,z),0,Vector3.one);Asset("district_deck",new Vector3(0,5.1f,z),0,Vector3.one);
    Asset("service_arch",new Vector3(0,0,z),0,Vector3.one);
    for(int side=-1;side<=1;side+=2){Asset("pipe_bank",new Vector3(side*3.7f,0,z),side<0?90:-90,Vector3.one);Asset("service_wall",new Vector3(side*4.25f,0,z),side<0?90:-90,Vector3.one);}
    Asset("practical_fixture",new Vector3(z%12==9?-3.8f:3.8f,3.1f,z),z%12==9?90:-90,Vector3.one,false);
    Light("Maintenance pool",new Vector3(z%12==9?-2.5f:2.5f,3.1f,z),z<60?amber:ice,z==63?130:75,7,z==51||z==69);
   }
   Solid("Undercity west wall",new Vector3(-4.2f,2.5f,60),new Vector3(.3f,5,36));Solid("Undercity east wall",new Vector3(4.2f,2.5f,60),new Vector3(.3f,5,36));
   Station(InteractionKind.Relay,"relay_a",new Vector3(-2.8f,0,46),90,"RELAY / BREATH","");
   Station(InteractionKind.Relay,"relay_b",new Vector3(2.8f,0,52),-90,"RELAY / MEMORY","");
   Station(InteractionKind.Relay,"relay_c",new Vector3(-2.8f,0,57),90,"RELAY / VOICE","");
   Asset("turbine",new Vector3(2.2f,0,58),-90,Vector3.one*.8f);Asset("turbine",new Vector3(-2.2f,0,67),90,Vector3.one*.8f);
   Sign("cipher",new Vector3(-3.85f,2.7f,61),-90,3.2f);Station(InteractionKind.Hack,"cipher",new Vector3(-2.8f,0,61),90,"LISTENING MACHINE","");
   // Alternating cover breaks the drone's visibility ray. The central lane stays navigable.
   for(int i=0;i<4;i++)Asset("crate",new Vector3(i%2==0?1.6f:-1.6f,0,64+i*2.7f),i*17,new Vector3(1.1f,1.3f,1.1f));
   Station(InteractionKind.Override,"security",new Vector3(2.7f,0,73),-90,"SECURITY OVERRIDE","");
   Station(InteractionKind.Memory,"memory_service",new Vector3(-2.7f,0,72),90,"READ THE WORKER'S LOG","Night shift, 04:17. The machine is not predicting the weather. It is listening to us dream.");
   Gate(new Vector3(0,0,76),MissionStage.Extract);Sign("ascent",new Vector3(0,3.7f,75.8f),0,3.8f);
  }
  static void Skyline(){
   for(int i=0;i<4;i++){Asset("ascent_stair",new Vector3(0,i*2,76+i*6),0,Vector3.one);Light("Amber ascent",new Vector3(1.8f,i*2+1,79+i*6),amber,40,5);}
   // Keep players on the physical stair while the adjoining skyline drops away.
   Solid("Ascent west barrier",new Vector3(-1.7f,6,88),new Vector3(.25f,13,24));Solid("Ascent east barrier",new Vector3(1.7f,6,88),new Vector3(.25f,13,24));
   for(int z=103;z<=109;z+=6)Asset("district_deck",new Vector3(0,8,z),0,Vector3.one);
   for(int z=102;z<=110;z+=4)for(int side=-1;side<=1;side+=2)Asset("railing",new Vector3(side*3.8f,8,z),90,Vector3.one);
   Asset("railing",new Vector3(0,8,112),0,new Vector3(1.3f,1,1));Solid("Platform end",new Vector3(0,10,112),new Vector3(8,4,.25f));
   Solid("Platform west",new Vector3(-4,10,106),new Vector3(.25f,4,12));Solid("Platform east",new Vector3(4,10,106),new Vector3(.25f,4,12));
   Station(InteractionKind.Extraction,"extraction",new Vector3(0,8,109),180,"TRANSMIT","");
   Asset("reactor",new Vector3(12,12,155),0,new Vector3(4,4,4),false);Light("Distant amber core",new Vector3(8,30,146),amber,18000,90);
   // Authored skyline rhythm: near dark shoulders frame a warm central negative space.
   int[] xs={-65,-44,-28,30,48,70,-82,82};int[] zs={135,156,128,140,167,126,195,205};
   for(int i=0;i<xs.Length;i++){float height=1.3f+(i%3)*.55f;Asset("tower",new Vector3(xs[i],-8,zs[i]),i*13,new Vector3(2,height,2),false);}
   for(int z=16;z<90;z+=22){Asset("tower",new Vector3(-25,0,z),0,new Vector3(1.2f,1.7f,1.2f),false);Asset("tower",new Vector3(25,0,z+8),14,new Vector3(1.4f,2.1f,1.4f),false);}
   Asset("signal_emblem",new Vector3(0,11,110),0,Vector3.one*1.6f,false).AddComponent<AmbientMotion>().rotationSpeed=new Vector3(0,0,5);
   Light("Platform blue edge",new Vector3(-3,10,103),ice,130,10,true);Light("Platform warm terminal",new Vector3(2,10,109),amber,110,7);
  }
  public static GameObject Asset(string name,Vector3 position,float yaw,Vector3 scale,bool collision=true){
   var prefab=AssetDatabase.LoadAssetAtPath<GameObject>("Assets/NR/Resources/NR/Models/"+name+".fbx");if(!prefab)throw new Exception("Missing model "+name);
   // Keep the FBX importer's root conversion intact. Placement belongs on a
   // separate parent: resetting the model root erased its unit scale and rotation.
   var model=(GameObject)PrefabUtility.InstantiatePrefab(prefab);
   Vector3 importedPosition=model.transform.localPosition;
   Quaternion importedRotation=model.transform.localRotation;
   Vector3 importedScale=model.transform.localScale;
   PrefabUtility.UnpackPrefabInstance(model,PrefabUnpackMode.Completely,InteractionMode.AutomatedAction);
   var go=new GameObject(name);go.transform.SetParent(root,false);
   model.transform.SetParent(go.transform,false);
   model.transform.localPosition=importedPosition;
   model.transform.localRotation=importedRotation;
   model.transform.localScale=importedScale;
   if(name=="ascent_stair"||name=="facade"||name=="district_deck"){
    var renderers=go.GetComponentsInChildren<MeshRenderer>();
    if(renderers.Length==0)throw new Exception("Imported model has no renderers: "+name);
    var bounds=renderers[0].bounds;
    foreach(var item in renderers)bounds.Encapsulate(item.bounds);
    bool valid=true;
    if(name=="ascent_stair"){
     // Normalize forward sign only after the importer's unit/up-axis conversion.
     if(bounds.center.z<go.transform.position.z)yaw+=180;
     valid=bounds.size.y>2.8f&&bounds.size.y<3.3f&&bounds.size.z>5.8f&&bounds.size.z<6.3f;
    }
    else if(name=="facade")valid=bounds.size.y>9.7f&&bounds.size.y<10.3f;
    else valid=bounds.size.x>7.8f&&bounds.size.x<8.2f&&bounds.size.z>5.8f&&bounds.size.z<6.2f;
    if(!valid)throw new Exception("Imported model unit/axis validation failed: "+name+" bounds="+bounds.size+" preserved FBX rotation="+importedRotation.eulerAngles+" scale="+importedScale);
   }
   go.transform.SetPositionAndRotation(position,Quaternion.Euler(0,yaw,0));go.transform.localScale=scale;
   foreach(var renderer in go.GetComponentsInChildren<MeshRenderer>()){
    var materials=renderer.sharedMaterials;for(int i=0;i<materials.Length;i++){string key=ResolveMaterialKey(name,materials[i]?materials[i].name:"metal");if(!ArtPipeline.Materials.TryGetValue(key,out var replacement))throw new Exception("Unmapped material "+key+" on "+name);materials[i]=replacement;}renderer.sharedMaterials=materials;renderer.gameObject.layer=8;
    var filter=renderer.GetComponent<MeshFilter>();if(collision&&filter&&filter.sharedMesh){var collider=renderer.gameObject.AddComponent<MeshCollider>();collider.sharedMesh=filter.sharedMesh;}
   }return go;
  }
  // FBX ImportStandard may name a material "district_deck-concrete" rather than
  // "concrete". Strip only this model's prefix, retaining strict unknown-slot errors.
  static string ResolveMaterialKey(string modelName,string importedName){
   string key=importedName.Trim().ToLowerInvariant();
   const string instanceSuffix=" (instance)";
   if(key.EndsWith(instanceSuffix,StringComparison.Ordinal))key=key.Substring(0,key.Length-instanceSuffix.Length);
   string model=modelName.ToLowerInvariant();
   foreach(string separator in new[]{"-","_","::","|"}){
    string prefix=model+separator;
    if(key.StartsWith(prefix,StringComparison.Ordinal)){key=key.Substring(prefix.Length);break;}
   }
   // Blender adds .001, .002, etc. when material datablock names collide.
   int dot=key.LastIndexOf('.');
   if(dot>0&&int.TryParse(key.Substring(dot+1),out _))key=key.Substring(0,dot);
   if((model=="district_deck"||model=="paving")&&key=="concrete")return "wet";
   return key;
  }
  static void Solid(string name,Vector3 position,Vector3 size){var go=new GameObject(name);go.transform.SetParent(root);go.transform.position=position;go.layer=8;go.AddComponent<BoxCollider>().size=size;}
  static void Gate(Vector3 at,MissionStage stage){var go=Asset("security_grille",at,0,new Vector3(2,1.35f,1));go.AddComponent<LiftGate>().openAt=stage;}
  static void Station(InteractionKind kind,string id,Vector3 pos,float angle,string caption,string story){var go=Asset("terminal",pos,angle,Vector3.one);go.name=id;var s=go.AddComponent<Interactable>();s.kind=kind;s.id=id;s.caption=caption;s.story=story;stations.Add(s);}
  static Light Light(string name,Vector3 position,Color color,float candela,float range,bool shadow=false,bool spot=false){var go=new GameObject(name);go.transform.SetParent(root);go.transform.position=position;var light=go.AddComponent<Light>();light.type=spot?LightType.Spot:LightType.Point;go.AddComponent<HDAdditionalLightData>();light.color=color;light.intensity=candela;light.range=range;light.shadows=shadow?LightShadows.Soft:LightShadows.None;if(shadow)shadowLights.Add(light);return light;}
  static void Sign(string name,Vector3 pos,float yaw,float width){
   var path=ArtPipeline.Generated+"/SignQuad.asset";var mesh=AssetDatabase.LoadAssetAtPath<Mesh>(path);
   if(!mesh){mesh=new Mesh{name="Printed sign surface"};mesh.vertices=new[]{new Vector3(-.5f,-.125f,0),new Vector3(.5f,-.125f,0),new Vector3(.5f,.125f,0),new Vector3(-.5f,.125f,0)};mesh.uv=new[]{Vector2.zero,Vector2.right,Vector2.one,Vector2.up};mesh.triangles=new[]{0,2,1,0,3,2};mesh.RecalculateNormals();mesh.RecalculateBounds();AssetDatabase.CreateAsset(mesh,path);}
   var go=new GameObject("Sign / "+name);go.transform.SetParent(root);go.transform.SetPositionAndRotation(pos,Quaternion.Euler(0,yaw,0));go.transform.localScale=Vector3.one*width;go.AddComponent<MeshFilter>().sharedMesh=mesh;go.AddComponent<MeshRenderer>().sharedMaterial=ArtPipeline.Materials["sign_"+name];
  }
  static AudioSource Loop(string name,float volume){var go=new GameObject("Ambience / "+name);var a=go.AddComponent<AudioSource>();a.clip=Resources.Load<AudioClip>("NR/Audio/"+name);if(!a.clip)throw new Exception("Missing audio "+name);a.loop=true;a.playOnAwake=true;a.volume=volume;a.spatialBlend=0;return a;}
  static ParticleSystem Rain(){var go=new GameObject("Rain / player-following bounded emitter");go.transform.position=new Vector3(0,12,15);var p=go.AddComponent<ParticleSystem>();p.Stop();var main=p.main;main.loop=true;main.startLifetime=1.3f;main.startSpeed=0;main.startSize=.04f;main.maxParticles=1800;main.simulationSpace=ParticleSystemSimulationSpace.World;main.startColor=new Color(.5f,.65f,.7f,.28f);var shape=p.shape;shape.shapeType=ParticleSystemShapeType.Box;shape.scale=new Vector3(18,1,22);var velocity=p.velocityOverLifetime;velocity.enabled=true;velocity.space=ParticleSystemSimulationSpace.World;velocity.x=.5f;velocity.y=-12;velocity.z=.2f;var em=p.emission;em.rateOverTime=850;var renderer=p.GetComponent<ParticleSystemRenderer>();renderer.renderMode=ParticleSystemRenderMode.Stretch;renderer.lengthScale=2;renderer.velocityScale=.045f;renderer.sharedMaterial=ArtPipeline.Materials["particle"];p.Play();return p;}
  static void Steam(Vector3 position){var go=new GameObject("Ventilation / drifting steam");go.transform.SetParent(root);go.transform.position=position;var p=go.AddComponent<ParticleSystem>();p.Stop();var main=p.main;main.startLifetime=3;main.startSpeed=.1f;main.startSize=.8f;main.maxParticles=45;main.startColor=new Color(.6f,.7f,.73f,.25f);main.simulationSpace=ParticleSystemSimulationSpace.World;var em=p.emission;em.rateOverTime=10;var shape=p.shape;shape.shapeType=ParticleSystemShapeType.Sphere;shape.radius=.15f;var v=p.velocityOverLifetime;v.enabled=true;v.space=ParticleSystemSimulationSpace.World;v.y=.35f;v.x=.12f;var size=p.sizeOverLifetime;size.enabled=true;size.size=new ParticleSystem.MinMaxCurve(1,AnimationCurve.Linear(0,.3f,1,1.7f));var renderer=p.GetComponent<ParticleSystemRenderer>();renderer.sharedMaterial=ArtPipeline.Materials["steam"];p.Play();}
  static void Probe(string name,Vector3 pos,Vector3 size){var go=new GameObject(name);go.transform.position=pos;var probe=go.AddComponent<ReflectionProbe>();probe.mode=ReflectionProbeMode.Realtime;probe.refreshMode=ReflectionProbeRefreshMode.OnAwake;probe.resolution=128;probe.size=size;probe.boxProjection=true;var data=go.AddComponent<HDAdditionalReflectionData>();data.mode=ProbeSettings.Mode.Realtime;data.realtimeMode=ProbeSettings.RealtimeMode.OnEnable;data.influenceVolume.boxSize=size;}
 }
}
