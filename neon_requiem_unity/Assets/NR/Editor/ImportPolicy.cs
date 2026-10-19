using UnityEditor;
using UnityEngine;
namespace NeonRequiem.Editor {
 public sealed class ImportPolicy : AssetPostprocessor {
  void OnPreprocessModel(){if(!assetPath.StartsWith("Assets/NR/Resources/NR/Models/"))return;var m=(ModelImporter)assetImporter;m.globalScale=1;m.bakeAxisConversion=true;m.useFileScale=true;m.importAnimation=false;m.importCameras=false;m.importLights=false;m.materialImportMode=ModelImporterMaterialImportMode.ImportStandard;m.isReadable=true;m.addCollider=false;m.importNormals=ModelImporterNormals.Import;m.importTangents=ModelImporterTangents.CalculateMikk;}
  void OnPreprocessTexture(){if(!assetPath.StartsWith("Assets/NR/Textures/"))return;var t=(TextureImporter)assetImporter;t.maxTextureSize=1024;t.mipmapEnabled=true;t.anisoLevel=4;if(assetPath.Contains("_normal")){t.textureType=TextureImporterType.NormalMap;t.sRGBTexture=false;}else if(assetPath.Contains("_mask")){t.textureType=TextureImporterType.Default;t.sRGBTexture=false;}t.textureCompression=TextureImporterCompression.CompressedHQ;}
  void OnPreprocessAudio(){if(!assetPath.StartsWith("Assets/NR/Resources/NR/Audio"))return;var a=(AudioImporter)assetImporter;var s=a.defaultSampleSettings;s.compressionFormat=AudioCompressionFormat.Vorbis;s.quality=.7f;s.loadType=assetPath.Contains("night")||assetPath.Contains("rain")?AudioClipLoadType.Streaming:AudioClipLoadType.DecompressOnLoad;a.defaultSampleSettings=s;}
 }
}
