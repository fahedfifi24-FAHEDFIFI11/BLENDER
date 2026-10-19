using System;
using System.IO;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
namespace NeonRequiem.Editor {
 public static class ArtPipeline {
  public const string Generated="Assets/NR/Generated";
  public static readonly Dictionary<string,Material> Materials=new Dictionary<string,Material>();
  public static HDRenderPipelineAsset pipeline;public static VolumeProfile volume;
  static Texture2D Texture(string name)=>AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/NR/Textures/"+name+".png");
  public static void Configure(){
   Directory.CreateDirectory(Generated);AssetDatabase.Refresh();
   pipeline=AssetDatabase.LoadAssetAtPath<HDRenderPipelineAsset>(Generated+"/RequiemHDRP.asset");
   if(!pipeline){pipeline=ScriptableObject.CreateInstance<HDRenderPipelineAsset>();AssetDatabase.CreateAsset(pipeline,Generated+"/RequiemHDRP.asset");}
   var r=pipeline.currentPlatformRenderPipelineSettings;r.supportSSR=true;r.supportSSAO=true;r.supportSSGI=true;r.supportVolumetrics=true;r.supportRayTracing=false;r.lightProbeSystem=RenderPipelineSettings.LightProbeSystem.LegacyLightProbes;pipeline.currentPlatformRenderPipelineSettings=r;
   GraphicsSettings.defaultRenderPipeline=pipeline;
   // Supply named levels without relying on a pre-existing template's quality settings.
   var quality=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/QualitySettings.asset")[0]);
   var levels=quality.FindProperty("m_QualitySettings");levels.arraySize=3;
   string[] names={"Medium","High","Ultra"};for(int i=0;i<3;i++){var level=levels.GetArrayElementAtIndex(i);level.FindPropertyRelative("name").stringValue=names[i];}
   quality.ApplyModifiedPropertiesWithoutUndo();
   for(int i=0;i<3;i++){QualitySettings.SetQualityLevel(i,false);QualitySettings.renderPipeline=pipeline;}QualitySettings.SetQualityLevel(1,false);
   PlayerSettings.colorSpace=ColorSpace.Linear;PlayerSettings.companyName="Low Tide Atelier";PlayerSettings.productName="Neon Requiem";
   PlayerSettings.defaultScreenWidth=1920;PlayerSettings.defaultScreenHeight=1080;PlayerSettings.fullScreenMode=FullScreenMode.FullScreenWindow;
   PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.StandaloneWindows64,false);
   PlayerSettings.SetGraphicsAPIs(BuildTarget.StandaloneWindows64,new[]{GraphicsDeviceType.Direct3D11,GraphicsDeviceType.Direct3D12});
   // Legacy keyboard/mouse backend is deliberate; no Input System package dependency.
   var playerSettings=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")[0]);
   var input=playerSettings.FindProperty("activeInputHandler");if(input==null)throw new Exception("Unity 6000.0 activeInputHandler setting not found");input.intValue=0;playerSettings.ApplyModifiedPropertiesWithoutUndo();
   Materials.Clear();
   Lit("metal",new Color(.65f,.74f,.77f),.75f,.55f,"metal");Lit("concrete",new Color(.68f,.73f,.74f),0,.25f,"concrete");
   Lit("bronze",new Color(.79f,.62f,.4f),.7f,.55f,"bronze");Lit("dark",new Color(.025f,.038f,.045f),.3f,.4f);
   Lit("ivory",new Color(.55f,.61f,.58f),.1f,.4f);Lit("glass",new Color(.02f,.065f,.085f),.6f,.92f);
   Lit("wet",new Color(.7f,.78f,.8f),.1f,.9f,"asphalt");
   Lit("cyan",new Color(.045f,.33f,.4f),.2f,.5f,null,new Color(.07f,.55f,.72f)*5);
   Lit("amber",new Color(.5f,.22f,.06f),.2f,.5f,null,new Color(1,.38f,.075f)*6);
   Lit("holo",new Color(.03f,.18f,.23f),.1f,.5f,null,new Color(.04f,.45f,.6f)*3);
   Lit("rain",new Color(.2f,.3f,.35f),.05f,.5f);
   foreach(var name in new[]{"market","mother","undercity","cipher","ascent","noodles","memory","corporate"}){
    var mat=NewMaterial("sign_"+name,"HDRP/Unlit");mat.SetColor("_UnlitColor",Color.white);mat.SetTexture("_UnlitColorMap",Texture("sign_"+name));mat.SetTexture("_EmissiveColorMap",Texture("sign_"+name));mat.SetColor("_EmissiveColor",Color.white*2);HDMaterial.ValidateMaterial(mat);Materials["sign_"+name]=mat;
   }
   var particle=NewMaterial("particle","HDRP/Unlit");particle.SetColor("_UnlitColor",new Color(.6f,.75f,.8f,.25f));particle.SetTexture("_UnlitColorMap",Texture("rain_particle"));particle.SetFloat("_SurfaceType",1);particle.SetFloat("_BlendMode",0);particle.SetFloat("_ZWrite",0);particle.renderQueue=3000;HDMaterial.ValidateMaterial(particle);Materials["particle"]=particle;
   var steam=NewMaterial("steam","HDRP/Unlit");steam.SetColor("_UnlitColor",new Color(.35f,.42f,.45f,.3f));steam.SetTexture("_UnlitColorMap",Texture("steam_particle"));steam.SetFloat("_SurfaceType",1);steam.SetFloat("_BlendMode",0);steam.SetFloat("_ZWrite",0);steam.renderQueue=3000;HDMaterial.ValidateMaterial(steam);Materials["steam"]=steam;
   volume=AssetDatabase.LoadAssetAtPath<VolumeProfile>(Generated+"/Atmosphere.asset");
   if(!volume){volume=ScriptableObject.CreateInstance<VolumeProfile>();AssetDatabase.CreateAsset(volume,Generated+"/Atmosphere.asset");}
   var fog=Component<Fog>();fog.enabled.Override(true);fog.enableVolumetricFog.Override(true);fog.meanFreePath.Override(55);fog.baseHeight.Override(-2);fog.maximumHeight.Override(65);fog.depthExtent.Override(96);fog.albedo.Override(new Color(.31f,.4f,.46f));fog.anisotropy.Override(.45f);
   var sky=Component<VisualEnvironment>();sky.skyType.Override((int)SkyType.Gradient);
   var gradient=Component<GradientSky>();gradient.top.Override(new Color(.015f,.025f,.045f));gradient.middle.Override(new Color(.07f,.095f,.12f));gradient.bottom.Override(new Color(.16f,.10f,.065f));
   var exposure=Component<Exposure>();exposure.mode.Override(ExposureMode.Automatic);exposure.limitMin.Override(3);exposure.limitMax.Override(7);exposure.compensation.Override(-.35f);exposure.adaptationSpeedDarkToLight.Override(1.5f);exposure.adaptationSpeedLightToDark.Override(.7f);
   var bloom=Component<Bloom>();bloom.intensity.Override(.16f);bloom.scatter.Override(.6f);
   var tone=Component<Tonemapping>();tone.mode.Override(TonemappingMode.ACES);
   var color=Component<ColorAdjustments>();color.saturation.Override(-12);color.contrast.Override(9);
   var vignette=Component<Vignette>();vignette.intensity.Override(.18f);
   var ssr=Component<ScreenSpaceReflection>();ssr.enabled.Override(true);ssr.tracing.Override(RayCastingMode.RayMarching);
   var ao=Component<ScreenSpaceAmbientOcclusion>();ao.intensity.Override(.65f);ao.radius.Override(.5f);
   var gi=Component<GlobalIllumination>();gi.enable.Override(false);gi.tracing.Override(RayCastingMode.RayMarching);
   EditorUtility.SetDirty(volume);EditorUtility.SetDirty(pipeline);AssetDatabase.SaveAssets();
  }
  static T Component<T>() where T:VolumeComponent {if(!volume.TryGet<T>(out var c)){c=volume.Add<T>(true);AssetDatabase.AddObjectToAsset(c,volume);}return c;}
  static Material NewMaterial(string name,string shader){var path=Generated+"/M_"+name+".mat";var mat=AssetDatabase.LoadAssetAtPath<Material>(path);if(!mat){var s=Shader.Find(shader);if(!s)throw new Exception("HDRP shader missing: "+shader);mat=new Material(s);AssetDatabase.CreateAsset(mat,path);}EditorUtility.SetDirty(mat);return mat;}
  static void Lit(string name,Color color,float metallic,float smooth,string texture=null,Color emission=default){
   var mat=NewMaterial(name,"HDRP/Lit");mat.SetColor("_BaseColor",color);mat.SetFloat("_Metallic",metallic);mat.SetFloat("_Smoothness",smooth);
   if(texture!=null){mat.SetTexture("_BaseColorMap",Texture(texture+"_color"));mat.SetTexture("_NormalMap",Texture(texture+"_normal"));mat.SetFloat("_NormalScale",.65f);mat.SetTexture("_MaskMap",Texture(texture+"_mask"));mat.SetFloat("_SmoothnessRemapMin",.15f);mat.SetFloat("_SmoothnessRemapMax",name=="wet"?.96f:.8f);}
   mat.SetColor("_EmissiveColor",emission);mat.enableInstancing=true;HDMaterial.ValidateMaterial(mat);Materials[name]=mat;
  }
 }
}
