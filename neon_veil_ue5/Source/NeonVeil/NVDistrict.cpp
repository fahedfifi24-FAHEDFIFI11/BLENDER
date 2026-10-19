#include "NVGame.h"
#include "Engine/World.h"
#include "Engine/StaticMesh.h"
#include "Components/StaticMeshComponent.h"
#include "Components/InstancedStaticMeshComponent.h"
#include "Components/BoxComponent.h"
#include "Components/TextRenderComponent.h"
#include "Components/PointLightComponent.h"
#include "Components/SpotLightComponent.h"
#include "Components/AudioComponent.h"
#include "Sound/SoundWave.h"
#include "Sound/SoundAttenuation.h"
#include "Engine/ExponentialHeightFog.h"
#include "Components/ExponentialHeightFogComponent.h"
#include "Engine/DirectionalLight.h"
#include "Components/DirectionalLightComponent.h"
#include "Engine/SkyLight.h"
#include "Components/SkyLightComponent.h"
#include "Engine/PostProcessVolume.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/MaterialInterface.h"
#include "Camera/CameraComponent.h"

ANVDistrict::ANVDistrict(){
 PrimaryActorTick.bCanEverTick=true;
 RootComponent=CreateDefaultSubobject<USceneComponent>(TEXT("DistrictRoot"));
}
UStaticMeshComponent* ANVDistrict::Asset(const FString& Name,FVector At,FRotator Rotation,FVector Scale,bool Collision){
 auto* Mesh=LoadObject<UStaticMesh>(nullptr,*FString::Printf(TEXT("/Game/NV/Meshes/%s.%s"),*Name,*Name));
 if(!Mesh){ UE_LOG(LogTemp,Error,TEXT("NEON VEIL missing imported mesh: %s. Run Tools/bootstrap.py."),*Name); return nullptr; }
 auto* C=NewObject<UStaticMeshComponent>(this);
 C->SetupAttachment(RootComponent);
 C->SetStaticMesh(Mesh); C->SetRelativeLocation(At*100); C->SetRelativeRotation(Rotation); C->SetRelativeScale3D(Scale);
 C->SetCollisionProfileName(Collision?TEXT("BlockAll"):TEXT("NoCollision"));
 C->SetMobility(EComponentMobility::Movable);
 C->RegisterComponent(); return C;
}
UBoxComponent* ANVDistrict::Block(FVector Center,FVector Extents){
 auto* C=NewObject<UBoxComponent>(this); C->SetupAttachment(RootComponent);
 C->SetRelativeLocation(Center*100); C->SetBoxExtent(Extents*100);
 C->SetCollisionProfileName(TEXT("BlockAll")); C->SetHiddenInGame(true); C->RegisterComponent(); return C;
}
void ANVDistrict::Sign(const FString& Text,FVector At,FRotator Rotation,FColor Color,float Size){
 auto* C=NewObject<UTextRenderComponent>(this); C->SetupAttachment(RootComponent);
 C->SetText(FText::FromString(Text)); C->SetRelativeLocation(At*100); C->SetRelativeRotation(Rotation);
 C->SetHorizontalAlignment(EHTA_Center); C->SetVerticalAlignment(EVRTA_TextCenter);
 C->SetTextRenderColor(Color); C->SetWorldSize(Size); C->RegisterComponent();
}
void ANVDistrict::Light(FVector At,FLinearColor Color,float Power,float Radius,bool Shadows){
 auto* C=NewObject<UPointLightComponent>(this); C->SetupAttachment(RootComponent);
 C->SetRelativeLocation(At*100); C->SetLightColor(Color); C->SetIntensity(Power);
 C->SetAttenuationRadius(Radius*100); C->SetCastShadows(Shadows);
 C->SetVolumetricScatteringIntensity(.7f); C->RegisterComponent();
}
void ANVDistrict::Play(const FString& Name,FVector At,float Volume){
 auto* Sound=LoadObject<USoundWave>(nullptr,*FString::Printf(TEXT("/Game/NV/Audio/%s.%s"),*Name,*Name));
 auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>();
 if(Sound) UGameplayStatics::PlaySoundAtLocation(this,Sound,At,Volume*(G?G->AudioVolume:.7f),1.f,0.f,SpatialAudio);
}
void ANVDistrict::SetAudio(float Volume){ for(int32 I=0;I<Loops.Num();++I) if(Loops[I]) Loops[I]->SetVolumeMultiplier(Volume*(I==0?.45f:.5f)); }
void ANVDistrict::BeginPlay(){ Super::BeginPlay(); Build(); }
void ANVDistrict::Build(){
 SpatialAudio=NewObject<USoundAttenuation>(this);
 SpatialAudio->Attenuation.bAttenuate=true; SpatialAudio->Attenuation.bSpatialize=true;
 SpatialAudio->Attenuation.AttenuationShapeExtents=FVector(200,0,0);
 SpatialAudio->Attenuation.FalloffDistance=3000;
 // Streets: all visible surfaces use original beveled FBX assets, never engine cubes.
 for(int32 X=0;X<8;++X) for(int32 Y=0;Y<2;++Y) Asset("paving",FVector(3+X*6,-3+Y*6,0));
 for(int32 Side : {-1,1}){
  for(int32 I=0;I<8;++I){
   float X=3+I*6;
   if((Side<0 && (I==2||I==3)) || (Side>0 && I==6)) continue;
   FRotator Face(0,Side<0?90:-90,0);
   Asset(I%3==0?"shutter":"facade",FVector(X,Side*6,0),Face);
   Asset("hvac",FVector(X+1.4f,Side*5.55f,4.6f),Face,FVector::OneVector,false);
   if(I%2==0) Asset("hvac",FVector(X-1.4f,Side*5.55f,7.2f),Face,FVector::OneVector,false);
   Asset("tower",FVector(X,Side*8.4f,10),Face,FVector(1,1,1+I%3*.2f),false);
  }
 }
 for(float X : {6.f,17.f,29.f,40.f}){
  Asset("cables",FVector(X,0,7),FRotator(0,90,0),FVector::OneVector,false);
  Light(FVector(X,-3.5f,4),FLinearColor(.18f,.64f,.85f),2400,9,true);
  Light(FVector(X+4,3.8f,3.5f),FLinearColor(1,.43f,.15f),1700,7,false);
 }
 Asset("skybridge",FVector(21,0,9),FRotator(0,90,0));
 Asset("stall",FVector(8,4.8f,0),FRotator(0,-90,0));
 Asset("terminal",Discovery*.01f,FRotator(0,-90,0));
 Sign("KASUMI / MEMORY EXCHANGE",FVector(8,-5.25f,3.6f),FRotator(0,90,0),FColor(91,218,229),36);
 Sign("RAMEN / LATE NIGHTS",FVector(9,5.2f,3.3f),FRotator(0,-90,0),FColor(244,164,94),30);
 Sign("MARKET / DOWN",FVector(15,-4.4f,3.3f),FRotator(0,180,0),FColor(91,218,229),33);
 Sign("HELIX NINE",FVector(26,0,5),FRotator(0,180,0),FColor(229,118,137),55);
 Sign("ROOF ACCESS / EAST",FVector(35.5f,4.2f,3),FRotator(0,-90,0),FColor(99,218,214),25);
 // Sunken market; a real sloped descent returns to the main street without a jump.
 for(float X : {15.f,21.f}) Asset("paving",FVector(X,-12,-1.8f));
 Asset("ramp",FVector(17.5f,-6,0),FRotator(0,-90,0));
 Asset("facade",FVector(18,-15,-1.8f),FRotator(0,90,0));
 Asset("canopy",FVector(18,-11,2.4f),FRotator::ZeroRotator,FVector(1.8f,1.6f,1),false);
 Asset("stall",FVector(15,-13,-1.8f),FRotator(0,90,0));
 Asset("stall",FVector(21,-13,-1.8f),FRotator(0,90,0));
 Asset("courier_torso",Broker*.01f+FVector(0,0,.88f),FRotator(0,90,0),FVector::OneVector,false);
 Asset("courier_head",Broker*.01f+FVector(0,0,1.51f),FRotator(0,90,0),FVector::OneVector,false);
 for(float Y : {-.15f,.15f}){
  Asset("courier_leg",Broker*.01f+FVector(Y,0,.88f),FRotator(0,90,0),FVector::OneVector,false);
  Asset("courier_arm",Broker*.01f+FVector(Y*2,0,1.42f),FRotator(0,90,0),FVector::OneVector,false);
 }
 Block(Broker*.01f+FVector(0,0,.8f),FVector(.35f,.3f,.8f));
 Sign("IVO / INFORMATION BROKER",Broker*.01f+FVector(0,0,2.2f),FRotator(0,90,0),FColor(183,220,215),24);
 Light(FVector(18,-11,1.2f),FLinearColor(.2f,.7f,.8f),1200,7,true);
 Light(FVector(15,-13,1),FLinearColor(1,.4f,.16f),1000,5);
 // Corporate entrance and solid flank barriers prevent bypassing the cipher gate.
 Gate=Asset("gate",FVector(26,0,0),FRotator::ZeroRotator,FVector::OneVector,false);
 GateBlock=Block(FVector(26,0,2),FVector(.35f,2.65f,2));
 for(float Y : {-4.3f,4.3f}) Asset("security_wall",FVector(26,Y,0));
 Asset("terminal",GateTerminal*.01f,FRotator(0,180,0));
 Asset("terminal",HackTerminal*.01f,FRotator(0,180,0));
 for(FVector P : {FVector(32,1.8f,0),FVector(36,-1.5f,0),FVector(40,1.6f,0),FVector(43,-2,0)}){
  Asset("crate",P,FRotator::ZeroRotator,FVector(1.8f,2,1.5f));
  Asset("crate",P+FVector(.2f,.1f,1.35f),FRotator(0,10,0),FVector(1.6f,1.8f,.5f));
 }
 Sign("NETWORK / SIGNAL ALIGNMENT",HackTerminal*.01f+FVector(0,0,2.2f),FRotator(0,180,0),FColor(90,210,226),22);
 // Three traversable flights, two landings and a roof deck; clear headroom at each turn.
 Asset("paving",FVector(38,7,0),FRotator::ZeroRotator,FVector(1,.5f,1));
 Asset("stairs",FVector(38,7,0));
 Asset("paving",FVector(44,8,2),FRotator::ZeroRotator,FVector(.67f,.67f,1));
 Asset("stairs",FVector(42,9,2),FRotator(0,180,0));
 Asset("paving",FVector(36,10,4),FRotator::ZeroRotator,FVector(.67f,.67f,1));
 Asset("stairs",FVector(38,11,4));
 Asset("paving",FVector(44,11,6),FRotator::ZeroRotator,FVector(.67f,.67f,1));
 for(float X : {35.f,41.f}) Asset("paving",FVector(X,15,6));
 for(float X : {32.f,38.f,44.f}) Asset("railing",FVector(X,18,6),FRotator::ZeroRotator);
 RoofDoor=Asset("gate",FVector(39,6.4f,0),FRotator(0,90,0),FVector::OneVector,false);
 RoofBlock=Block(FVector(39,6.4f,2),FVector(3.05f,.35f,2));
 Asset("terminal",Extraction*.01f,FRotator(0,180,0));
 Light(FVector(40,10,6),FLinearColor(.25f,.7f,.85f),2100,9);
 Light(FVector(35,16,8),FLinearColor(1,.43f,.12f),2000,12);
 Sign("EXTRACTION / GHOST SIGNAL",Extraction*.01f+FVector(0,0,2.2f),FRotator(0,180,0),FColor(249,184,115),25);
 // Peripheral collision follows visible architecture; the market and roof entrances stay open.
 Block(FVector(-.5f,0,3),FVector(.5f,6,3));
 Block(FVector(48.5f,0,3),FVector(.5f,6,3));
 for(int32 Side : {-1,1}) for(int32 I=0;I<8;++I){
  if((Side<0&&(I==2||I==3))||(Side>0&&I==6)) continue;
  Block(FVector(3+I*6,Side*6.1f,5),FVector(3,.2f,5));
 }
 Block(FVector(18,-15.4f,0),FVector(6,.3f,3));
 Block(FVector(11.8f,-11,0),FVector(.2f,4,3));
 Block(FVector(24.2f,-11,0),FVector(.2f,4,3));
 // Layered skyline, manufactured solar turbine, animated advertising and traffic drone.
 Asset("reactor",FVector(65,10,12),FRotator(0,180,0),FVector(1.5f),false);
 for(int32 I=0;I<10;++I) Asset("tower",FVector(57+(I%3)*7,-22+I*6,0),FRotator::ZeroRotator,FVector(1.7f,1.3f,2+(I%4)*.4f),false);
 Light(FVector(55,10,13),FLinearColor(1,.35f,.07f),45000,45,false);
 for(FVector P : {FVector(6,-4.5f,5),FVector(20,4.7f,4.8f),FVector(38,-4.8f,5)}){
  auto* H=Asset("hologram",P,FRotator::ZeroRotator,FVector::OneVector,false); if(H) Holograms.Add(H);
 }
 Drone=Asset("drone",FVector(20,0,9),FRotator::ZeroRotator,FVector::OneVector,false);
 auto* Fog=GetWorld()->SpawnActor<AExponentialHeightFog>();
 Fog->GetComponent()->SetFogDensity(.025f); Fog->GetComponent()->SetFogHeightFalloff(.2f);
 Fog->GetComponent()->SetFogInscatteringColor(FLinearColor(.12f,.23f,.29f));
 Fog->GetComponent()->SetVolumetricFog(true);
 auto* Sun=GetWorld()->SpawnActor<ADirectionalLight>();
 Sun->SetActorRotation(FRotator(-40,-35,0));
 Sun->GetLightComponent()->SetIntensity(.35f); Sun->GetLightComponent()->SetLightColor(FLinearColor(.32f,.53f,.7f));
 auto* Sky=GetWorld()->SpawnActor<ASkyLight>();
 Sky->GetLightComponent()->SetIntensity(.4f); Sky->GetLightComponent()->SetLightColor(FLinearColor(.2f,.35f,.5f));
 auto* Post=GetWorld()->SpawnActor<APostProcessVolume>(); Post->bUnbound=true;
 Post->Settings.bOverride_AutoExposureMethod=true; Post->Settings.AutoExposureMethod=EAutoExposureMethod::AEM_Manual;
 Post->Settings.bOverride_AutoExposureBias=true; Post->Settings.AutoExposureBias=1.0f;
 Post->Settings.bOverride_BloomIntensity=true; Post->Settings.BloomIntensity=.35f;
 Post->Settings.bOverride_VignetteIntensity=true; Post->Settings.VignetteIntensity=.25f;
 // Efficient original mesh rain; Niagara assets are not assumed or downloaded.
 Rain=NewObject<UInstancedStaticMeshComponent>(this); Rain->SetupAttachment(RootComponent);
 Rain->SetStaticMesh(LoadObject<UStaticMesh>(nullptr,TEXT("/Game/NV/Meshes/rain_drop.rain_drop")));
 Rain->SetCollisionEnabled(ECollisionEnabled::NoCollision); Rain->SetCastShadow(false); Rain->RegisterComponent();
 FRandomStream R(7102);
 for(int32 I=0;I<700;++I) Rain->AddInstance(FTransform(FVector(R.FRandRange(0,4800),R.FRandRange(-550,550),R.FRandRange(30,1200))));
 for(const TCHAR* Name : {TEXT("night"),TEXT("rain"),TEXT("vent")}){
  auto* A=NewObject<UAudioComponent>(this); A->SetupAttachment(RootComponent);
  A->SetSound(LoadObject<USoundWave>(nullptr,*FString::Printf(TEXT("/Game/NV/Audio/%s.%s"),Name,Name)));
  A->bAutoActivate=false; A->RegisterComponent(); A->Play(); Loops.Add(A);
 }
 SetAudio(.7f);
 ObjectiveMarker=NewObject<UTextRenderComponent>(this); ObjectiveMarker->SetupAttachment(RootComponent);
 ObjectiveMarker->SetText(FText::FromString(TEXT("[ SIGNAL ]"))); ObjectiveMarker->SetWorldSize(22);
 ObjectiveMarker->SetTextRenderColor(FColor(108,223,227)); ObjectiveMarker->SetHorizontalAlignment(EHTA_Center); ObjectiveMarker->RegisterComponent();
}
void ANVDistrict::ResetDistrict(){
 for(auto* E:Enemies) if(IsValid(E)) E->Destroy(); Enemies.Empty(); GateOpen=false; RoofOpen=false;
 if(Gate) Gate->SetRelativeLocation(FVector(2600,0,0));
 if(RoofDoor) RoofDoor->SetRelativeLocation(FVector(3900,640,0));
 if(GateBlock) GateBlock->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
 if(RoofBlock) RoofBlock->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
}
void ANVDistrict::SpawnSecurity(){
 const FVector Positions[]={FVector(36,-3,1),FVector(40,3,1),FVector(44,-3,1),FVector(43,2,1),FVector(46,0,1)};
 for(int32 I=0;I<5;++I){
  FTransform T(FRotator(0,180,0),Positions[I]*100);
  auto* E=GetWorld()->SpawnActorDeferred<ANVEnemy>(ANVEnemy::StaticClass(),T,this,nullptr,ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn);
  E->Rusher=I>=3; UGameplayStatics::FinishSpawningActor(E,T); Enemies.Add(E);
 }
}
void ANVDistrict::Tick(float D){
 Super::Tick(D); Time+=D;
 if(FMath::Fmod(Time,37.f)<D) Play("thunder",FVector(3800,0,1800),.45f);
 if(Gate){ FVector P=Gate->GetRelativeLocation(); P.Z=FMath::FInterpConstantTo(P.Z,GateOpen?500.f:0.f,D,180); Gate->SetRelativeLocation(P); GateBlock->SetCollisionEnabled(P.Z>230?ECollisionEnabled::NoCollision:ECollisionEnabled::QueryAndPhysics); }
 if(RoofDoor){ FVector P=RoofDoor->GetRelativeLocation(); P.Z=FMath::FInterpConstantTo(P.Z,RoofOpen?400.f:0.f,D,160); RoofDoor->SetRelativeLocation(P); RoofBlock->SetCollisionEnabled(P.Z>220?ECollisionEnabled::NoCollision:ECollisionEnabled::QueryAndPhysics); }
 for(auto* H:Holograms) if(H) H->AddLocalRotation(FRotator(0,D*12,0));
 if(Drone) Drone->SetRelativeLocation(FVector(2100+FMath::Sin(Time*.08f)*1500,FMath::Sin(Time*.12f)*300,950));
 RainClock+=D;
 if(Rain && RainClock>.033f){
  float Step=RainClock; RainClock=0;
  for(int32 I=0;I<Rain->GetInstanceCount();++I){ FTransform T; Rain->GetInstanceTransform(I,T); FVector P=T.GetLocation(); P.Z-=Step*850; if(P.Z<20) P.Z+=1180; T.SetLocation(P); Rain->UpdateInstanceTransform(I,T,false,false,true); }
  Rain->MarkRenderStateDirty();
 }
 auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>();
 if(G && G->Player && Loops.Num()>1){ bool Interior=G->Player->GetActorLocation().Y<-700; Loops[1]->SetVolumeMultiplier(G->AudioVolume*(Interior?.12f:.55f)); }
}
