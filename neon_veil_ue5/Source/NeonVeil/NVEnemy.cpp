#include "NVGame.h"
#include "Engine/World.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Engine/StaticMesh.h"
#include "Engine/DamageEvents.h"
#include "GameFramework/DamageType.h"
#include "TimerManager.h"
#include "Camera/CameraComponent.h"

ANVEnemy::ANVEnemy(){
 PrimaryActorTick.bCanEverTick=true;
 GetCapsuleComponent()->InitCapsuleSize(35,90);
 GetCapsuleComponent()->SetCollisionResponseToChannel(ECC_Visibility,ECR_Block);
 GetCharacterMovement()->bRunPhysicsWithNoController=true;
 GetCharacterMovement()->bOrientRotationToMovement=false;
 GetCharacterMovement()->MaxWalkSpeed=250;
 Visual=CreateDefaultSubobject<USceneComponent>(TEXT("SecuritySuit"));
 Visual->SetupAttachment(RootComponent);
 Visual->SetRelativeLocation(FVector(0,0,-90));
 Indicator=CreateDefaultSubobject<UTextRenderComponent>(TEXT("HealthAndTelegraph"));
 Indicator->SetupAttachment(RootComponent);
 Indicator->SetRelativeLocation(FVector(0,0,120));
 Indicator->SetHorizontalAlignment(EHTA_Center);
 Indicator->SetWorldSize(19);
 Indicator->SetTextRenderColor(FColor(220,120,95));
}
void ANVEnemy::BeginPlay(){
 Super::BeginPlay();
 Health=Rusher?90:65;
 GetCharacterMovement()->MaxWalkSpeed=Rusher?430:230;
 const TCHAR* Files[]={TEXT("security_torso"),TEXT("courier_head"),TEXT("courier_leg"),TEXT("courier_leg"),TEXT("courier_arm"),TEXT("courier_arm"),TEXT("rifle")};
 const FVector Positions[]={FVector(0,0,88),FVector(0,0,151),FVector(0,-15,88),FVector(0,15,88),FVector(0,-31,142),FVector(0,31,142),FVector(25,29,112)};
 for(int32 N=0;N<7;++N){
  auto* C=NewObject<UStaticMeshComponent>(this);
  C->SetupAttachment(Visual);
  C->SetStaticMesh(LoadObject<UStaticMesh>(nullptr,*FString::Printf(TEXT("/Game/NV/Meshes/%s.%s"),Files[N],Files[N])));
  C->SetCollisionEnabled(ECollisionEnabled::NoCollision);
  C->SetRelativeLocation(Positions[N]); C->RegisterComponent(); Limbs.Add(C);
 }
 Indicator->SetText(FText::FromString(Rusher?TEXT("BREACHER"):TEXT("MARKSMAN")));
}
void ANVEnemy::Tick(float D){
 Super::Tick(D);
 auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>();
 if(!G || G->Mode!=ENVMode::Playing || !G->Player) return;
 if(Dead){ DeathClock+=D; if(DeathClock>3) Destroy(); return; }
 FVector To=G->Player->GetActorLocation()-GetActorLocation(); To.Z=0;
 float Distance=To.Size(); FVector Dir=To.GetSafeNormal();
 SetActorRotation(FMath::RInterpTo(GetActorRotation(),Dir.Rotation(),D,8));
 Indicator->SetWorldRotation((G->Player->Camera->GetComponentLocation()-Indicator->GetComponentLocation()).Rotation());
 Clock-=D;
 if(Stagger>0){ Stagger-=D; State=EState::Stagger; return; }
 if(State==EState::Stagger) State=EState::Chase;
 if(State==EState::Windup){
  Indicator->SetText(FText::FromString(Rusher?TEXT("BREACH / EVADE"):TEXT("AIMING / TAKE COVER")));
  if(Clock<=0){ Attack(); State=EState::Recover; Clock=Rusher?1.05f:1.5f; }
  return;
 }
 if(State==EState::Recover){ if(Clock<=0) State=EState::Chase; return; }
 Indicator->SetText(FText::FromString(FString::Printf(TEXT("%s  %d"),Rusher?TEXT("BREACHER"):TEXT("MARKSMAN"),FMath::CeilToInt(Health))));
 FCollisionQueryParams Q(SCENE_QUERY_STAT(SecuritySight),false,this);
 FHitResult Hit;
 bool Blocked=GetWorld()->LineTraceSingleByChannel(Hit,GetActorLocation()+FVector(0,0,35),G->Player->GetActorLocation(),ECC_Visibility,Q);
 bool Sees=!Blocked || Hit.GetActor()==G->Player;
 if(!Rusher && Sees && Distance<380){ AddMovementInput(-Dir); return; }
 if(Distance<(Rusher?155:1150) && Sees){ State=EState::Windup; Clock=Rusher?.55f:.85f; return; }
 FVector Move=Dir;
 if(!Rusher && Sees && Distance<500) Move=-Dir;
 // Local collision steering around authored cover; no baked navmesh dependency.
 FCollisionQueryParams SteerQ(SCENE_QUERY_STAT(SecuritySteer),false,this); SteerQ.AddIgnoredActor(G->Player);
 FHitResult Obstacle;
 if(GetWorld()->LineTraceSingleByChannel(Obstacle,GetActorLocation(),GetActorLocation()+Move*140,ECC_Visibility,SteerQ)){
  for(float Angle : {60.f,-60.f,100.f,-100.f}){
   FVector Candidate=Move.RotateAngleAxis(Angle,FVector::UpVector);
   if(!GetWorld()->LineTraceSingleByChannel(Obstacle,GetActorLocation(),GetActorLocation()+Candidate*150,ECC_Visibility,SteerQ)){ Move=Candidate; break; }
  }
 }
 AddMovementInput(Move);
 const float Phase=GetWorld()->GetTimeSeconds()*(Rusher?11.f:7.f);
 if(Limbs.Num()>3){ Limbs[2]->SetRelativeRotation(FRotator(FMath::Sin(Phase)*28,0,0)); Limbs[3]->SetRelativeRotation(FRotator(-FMath::Sin(Phase)*28,0,0)); }
}
void ANVEnemy::Attack(){
 auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>(); if(!G || !G->Player || Dead) return;
 ++AttackIndex;
 FVector From=GetActorLocation()+FVector(0,0,35), To=G->Player->GetActorLocation();
 FCollisionQueryParams Q(SCENE_QUERY_STAT(SecurityShot),true,this);
 FHitResult Hit;
 bool Blocked=GetWorld()->LineTraceSingleByChannel(Hit,From,To,ECC_Visibility,Q);
 if(Rusher){
  if(FVector::Dist(From,To)<190 && (!Blocked || Hit.GetActor()==G->Player)) UGameplayStatics::ApplyDamage(G->Player,20,nullptr,this,UDamageType::StaticClass());
  G->District->Play("impact",From,.7f);
 }else{
  // Telegraph is long enough to leave the line of fire; final trace honors cover.
  FVector End=Blocked?Hit.ImpactPoint:To;
  if(Hit.GetActor()==G->Player) UGameplayStatics::ApplyDamage(G->Player,12,nullptr,this,UDamageType::StaticClass());
  FVector Delta=End-From;
  auto* Tracer=G->District->Asset("tracer",From*.01f,Delta.Rotation(),FVector(Delta.Size()/100.f,1,1),false);
  TWeakObjectPtr<UStaticMeshComponent> Weak=Tracer; FTimerHandle Handle;
  GetWorldTimerManager().SetTimer(Handle,[Weak](){if(Weak.IsValid()) Weak->DestroyComponent();},.07f,false);
  G->District->Play("shot",From,.55f);
 }
}
float ANVEnemy::TakeDamage(float Amount,FDamageEvent const& Event,AController* Instigator,AActor* Causer){
 if(Dead || Amount<=0) return 0;
 Health=FMath::Max(0.f,Health-Amount); Stagger=Rusher?.12f:.28f;
 if(Health<=0){
  Dead=true; State=EState::Dead; GetCapsuleComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
  GetCharacterMovement()->StopMovementImmediately(); GetCharacterMovement()->DisableMovement();
  Visual->SetRelativeRotation(FRotator(0,0,82)); Indicator->SetVisibility(false);
  if(auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>()) G->EnemyDefeated();
 }
 return Amount;
}
