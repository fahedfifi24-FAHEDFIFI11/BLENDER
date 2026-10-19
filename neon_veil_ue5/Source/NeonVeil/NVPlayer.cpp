#include "NVGame.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/InputComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "Engine/StaticMesh.h"
#include "TimerManager.h"
#include "GameFramework/DamageType.h"
#include "Engine/DamageEvents.h"

static UStaticMeshComponent* Part(AActor* Owner, USceneComponent* Parent, const TCHAR* File, FVector At) {
 auto* C = NewObject<UStaticMeshComponent>(Owner);
 C->SetupAttachment(Parent);
 C->SetStaticMesh(LoadObject<UStaticMesh>(nullptr,*FString::Printf(TEXT("/Game/NV/Meshes/%s.%s"),File,File)));
 C->SetCollisionEnabled(ECollisionEnabled::NoCollision);
 C->SetRelativeLocation(At);
 C->RegisterComponent();
 return C;
}
ANVPlayer::ANVPlayer() {
 PrimaryActorTick.bCanEverTick = true;
 GetCapsuleComponent()->InitCapsuleSize(34,90);
 GetCapsuleComponent()->SetCollisionResponseToChannel(ECC_Visibility,ECR_Block);
 bUseControllerRotationYaw = false;
 GetCharacterMovement()->bOrientRotationToMovement = true;
 GetCharacterMovement()->RotationRate = FRotator(0,600,0);
 GetCharacterMovement()->MaxWalkSpeed = 360;
 GetCharacterMovement()->MaxAcceleration = 1800;
 GetCharacterMovement()->BrakingDecelerationWalking = 1500;
 GetCharacterMovement()->JumpZVelocity = 520;
 GetCharacterMovement()->AirControl = .35f;
 GetCharacterMovement()->GetNavAgentPropertiesRef().bCanCrouch = true;
 GetCharacterMovement()->MaxWalkSpeedCrouched = 180;
 GetCharacterMovement()->CrouchedHalfHeight = 58;
 Boom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CollisionCameraArm"));
 Boom->SetupAttachment(RootComponent);
 Boom->TargetArmLength = 340;
 Boom->SocketOffset = FVector(0,65,70);
 Boom->bUsePawnControlRotation = true;
 Boom->bEnableCameraLag = true;
 Boom->CameraLagSpeed = 12;
 Boom->ProbeSize = 12;
 Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
 Camera->SetupAttachment(Boom);
 Camera->FieldOfView = 78;
 Visual = CreateDefaultSubobject<USceneComponent>(TEXT("ArticulatedOperative"));
 Visual->SetupAttachment(RootComponent);
 Visual->SetRelativeLocation(FVector(0,0,-90));
}
void ANVPlayer::BeginPlay() {
 Super::BeginPlay();
 Part(this,Visual,TEXT("courier_torso"),FVector(0,0,88));
 Part(this,Visual,TEXT("courier_head"),FVector(0,0,151));
 Limbs.Add(Part(this,Visual,TEXT("courier_leg"),FVector(0,-15,88)));
 Limbs.Add(Part(this,Visual,TEXT("courier_leg"),FVector(0,15,88)));
 Limbs.Add(Part(this,Visual,TEXT("courier_arm"),FVector(0,-31,142)));
 Limbs.Add(Part(this,Visual,TEXT("courier_arm"),FVector(0,31,142)));
 Weapon = Part(this,Visual,TEXT("rifle"),FVector(24,29,112));
}
bool ANVPlayer::CanAct() const {
 auto* G = GetWorld()->GetAuthGameMode<ANVGameMode>();
 return G && G->Mode==ENVMode::Playing && Health>0;
}
void ANVPlayer::SetupPlayerInputComponent(UInputComponent* I) {
 Super::SetupPlayerInputComponent(I);
 I->BindAxis("MoveForward",this,&ANVPlayer::Forward);
 I->BindAxis("MoveRight",this,&ANVPlayer::Right);
 I->BindAxis("Turn",this,&ANVPlayer::Turn);
 I->BindAxis("LookUp",this,&ANVPlayer::Look);
 I->BindAction("Jump",IE_Pressed,this,&ANVPlayer::JumpOn);
 I->BindAction("Jump",IE_Released,this,&ANVPlayer::JumpOff);
 I->BindAction("Sprint",IE_Pressed,this,&ANVPlayer::SprintOn);
 I->BindAction("Sprint",IE_Released,this,&ANVPlayer::SprintOff);
 I->BindAction("Crouch",IE_Pressed,this,&ANVPlayer::CrouchOn);
 I->BindAction("Crouch",IE_Released,this,&ANVPlayer::CrouchOff);
 I->BindAction("Aim",IE_Pressed,this,&ANVPlayer::AimOn);
 I->BindAction("Aim",IE_Released,this,&ANVPlayer::AimOff);
 I->BindAction("Fire",IE_Pressed,this,&ANVPlayer::FirePressed).bExecuteWhenPaused = true;
 I->BindAction("Fire",IE_Released,this,&ANVPlayer::FireReleased).bExecuteWhenPaused = true;
 I->BindAction("Reload",IE_Pressed,this,&ANVPlayer::Reload);
 I->BindAction("Interact",IE_Pressed,this,&ANVPlayer::Interact);
 I->BindAction("Pause",IE_Pressed,this,&ANVPlayer::Pause).bExecuteWhenPaused = true;
}
void ANVPlayer::Forward(float V) { if(CanAct()) AddMovementInput(FRotationMatrix(FRotator(0,GetControlRotation().Yaw,0)).GetUnitAxis(EAxis::X),V); }
void ANVPlayer::Right(float V) { if(CanAct()) AddMovementInput(FRotationMatrix(FRotator(0,GetControlRotation().Yaw,0)).GetUnitAxis(EAxis::Y),V); }
void ANVPlayer::Turn(float V) { if(CanAct()) AddControllerYawInput(V*.8f); }
void ANVPlayer::Look(float V) { if(CanAct()) AddControllerPitchInput(V*.65f); }
void ANVPlayer::SprintOn(){ Sprinting=CanAct(); }
void ANVPlayer::SprintOff(){ Sprinting=false; }
void ANVPlayer::AimOn(){ Aiming=CanAct(); }
void ANVPlayer::AimOff(){ Aiming=false; }
void ANVPlayer::CrouchOn(){ if(CanAct()) Crouch(); }
void ANVPlayer::CrouchOff(){ UnCrouch(); }
void ANVPlayer::JumpOn(){ if(CanAct()) Jump(); }
void ANVPlayer::JumpOff(){ StopJumping(); }
void ANVPlayer::Pause(){ if(auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>()) G->TogglePause(); }
void ANVPlayer::Interact(){ if(CanAct()) GetWorld()->GetAuthGameMode<ANVGameMode>()->Interact(); }
void ANVPlayer::FirePressed(){
 auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>();
 if(!G) return;
 if(G->Mode!=ENVMode::Playing){
  if(auto* PC=Cast<APlayerController>(Controller)) if(auto* H=Cast<ANVHUD>(PC->GetHUD())) H->Click();
  return;
 }
 TriggerHeld=true;
 Shoot();
}
void ANVPlayer::FireReleased(){ TriggerHeld=false; }
void ANVPlayer::Reload(){ if(CanAct() && ReloadTime<=0 && Ammo<18){ ReloadTime=1.4f; TriggerHeld=false; GetWorld()->GetAuthGameMode<ANVGameMode>()->District->Play("reload",GetActorLocation()); } }
void ANVPlayer::Shoot(){
 if(!CanAct() || FireCooldown>0 || ReloadTime>0) return;
 if(Ammo<=0){ Reload(); return; }
 auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>();
 --Ammo; FireCooldown=.19f;
 FVector Eye=Camera->GetComponentLocation();
 FVector Direction=Camera->GetForwardVector();
 Direction=FMath::VRandCone(Direction,FMath::DegreesToRadians(Aiming?.25f:1.4f));
 FCollisionQueryParams Q(SCENE_QUERY_STAT(CourierAim),true,this);
 FHitResult Aim;
 FVector AimPoint=Eye+Direction*8000;
 if(GetWorld()->LineTraceSingleByChannel(Aim,Eye,AimPoint,ECC_Visibility,Q)) AimPoint=Aim.ImpactPoint;
 const FVector Muzzle=Weapon->GetComponentLocation()+GetActorForwardVector()*75;
 FHitResult Hit;
 FVector End=AimPoint;
 // The second trace prevents shooting through cover beside an offset camera.
 if(GetWorld()->LineTraceSingleByChannel(Hit,Muzzle,AimPoint,ECC_Visibility,Q)){
  End=Hit.ImpactPoint;
  if(auto* Enemy=Cast<ANVEnemy>(Hit.GetActor())){
   UGameplayStatics::ApplyPointDamage(Enemy,26,Direction,Hit,Controller,this,UDamageType::StaticClass());
   HitFlash=.13f;
  }
 }
 // Original emissive mesh tracers are visible in Shipping (no debug-draw dependency).
 FVector Delta=End-Muzzle;
 if(auto* Tracer=G->District->Asset("tracer",Muzzle*.01f,Delta.Rotation(),FVector(Delta.Size()/100.f,1,1),false)){
  TWeakObjectPtr<UStaticMeshComponent> Weak=Tracer;
  FTimerHandle Handle;
  GetWorldTimerManager().SetTimer(Handle,[Weak](){ if(Weak.IsValid()) Weak->DestroyComponent(); },.055f,false);
 }
 G->District->Play("shot",Muzzle,.8f);
 AddControllerPitchInput(-.22f);
}
void ANVPlayer::Tick(float D){
 Super::Tick(D);
 if(!CanAct()) return;
 FireCooldown=FMath::Max(0.f,FireCooldown-D);
 HitFlash=FMath::Max(0.f,HitFlash-D);
 if(ReloadTime>0){ ReloadTime-=D; if(ReloadTime<=0) Ammo=18; }
 if(TriggerHeld) Shoot();
 GetCharacterMovement()->MaxWalkSpeed=Aiming?230.f:(Sprinting?620.f:360.f);
 GetCharacterMovement()->bOrientRotationToMovement=!Aiming;
 bUseControllerRotationYaw=Aiming;
 Boom->TargetArmLength=FMath::FInterpTo(Boom->TargetArmLength,Aiming?190.f:340.f,D,9);
 Camera->SetFieldOfView(FMath::FInterpTo(Camera->FieldOfView,Aiming?62.f:78.f,D,8));
 const float Speed=GetVelocity().Size2D();
 Gait+=D*Speed*.022f;
 const float Stride=FMath::Sin(Gait)*FMath::Clamp(Speed/360.f,0.f,1.3f)*32;
 if(Limbs.Num()==4){
  Limbs[0]->SetRelativeRotation(FRotator(Stride,0,0));
  Limbs[1]->SetRelativeRotation(FRotator(-Stride,0,0));
  Limbs[2]->SetRelativeRotation(FRotator(Aiming?-65.f:-Stride*.5f,0,0));
  Limbs[3]->SetRelativeRotation(FRotator(Aiming?-70.f:Stride*.5f,0,0));
 }
 Visual->SetRelativeLocation(FVector(0,0,bIsCrouched?-61.f:-90.f));
 StepClock-=D;
 if(Speed>70 && GetCharacterMovement()->IsMovingOnGround() && StepClock<=0){
  GetWorld()->GetAuthGameMode<ANVGameMode>()->District->Play("step",GetActorLocation(),.45f);
  StepClock=Sprinting?.3f:.48f;
 }
 if(GetActorLocation().Z < -1000){ FDamageEvent E; TakeDamage(1000,E,nullptr,this); }
}
float ANVPlayer::TakeDamage(float Amount,FDamageEvent const& E,AController* I,AActor* C){
 if(!CanAct() || Amount<=0) return 0;
 Health=FMath::Max(0.f,Health-Amount);
 auto* G=GetWorld()->GetAuthGameMode<ANVGameMode>();
 G->Say(TEXT("SUIT / Impact detected. Use solid cover and break their line of sight."),2);
 G->District->Play("hurt",GetActorLocation());
 if(G->Hacking){ G->Hacking=false; G->HackSuccess=0; }
 if(Health<=0) G->Die();
 return Amount;
}
void ANVPlayer::ResetOperative(){
 Health=100; Ammo=18; ReloadTime=0; FireCooldown=0; TriggerHeld=false; Aiming=false; Sprinting=false;
 UnCrouch(); GetCharacterMovement()->StopMovementImmediately(); GetCharacterMovement()->SetMovementMode(MOVE_Walking);
 SetActorLocationAndRotation(FVector(100,0,100),FRotator::ZeroRotator,false,nullptr,ETeleportType::TeleportPhysics);
 if(Controller) Controller->SetControlRotation(FRotator(-8,0,0));
}
