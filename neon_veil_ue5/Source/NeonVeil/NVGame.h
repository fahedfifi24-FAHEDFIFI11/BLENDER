#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "GameFramework/GameModeBase.h"
#include "GameFramework/HUD.h"
#include "NVGame.generated.h"
class USpringArmComponent;
class UCameraComponent;
class UStaticMeshComponent;
class UInstancedStaticMeshComponent;
class UAudioComponent;
class USoundWave;
class USoundAttenuation;
class UTextRenderComponent;
class UBoxComponent;
class ANVDistrict;
class ANVEnemy;

UENUM()
enum class ENVMode : uint8 { Title, Playing, Paused, Dead, Victory };
UENUM()
enum class ENVMission : uint8 { Broker, Facility, Hack, Combat, Rooftop, Complete };

UCLASS()
class NEONVEIL_API ANVPlayer : public ACharacter {
 GENERATED_BODY()
public:
 ANVPlayer();
 virtual void BeginPlay() override;
 virtual void Tick(float Delta) override;
 virtual void SetupPlayerInputComponent(UInputComponent* Input) override;
 virtual float TakeDamage(float Amount, FDamageEvent const& Event, AController* Instigator, AActor* Causer) override;
 UPROPERTY(VisibleAnywhere) USpringArmComponent* Boom;
 UPROPERTY(VisibleAnywhere) UCameraComponent* Camera;
 UPROPERTY(VisibleAnywhere) USceneComponent* Visual;
 UPROPERTY() TArray<UStaticMeshComponent*> Limbs;
 UPROPERTY() UStaticMeshComponent* Weapon;
 float Health = 100;
 int32 Ammo = 18;
 bool Aiming = false;
 bool Sprinting = false;
 bool TriggerHeld = false;
 float ReloadTime = 0;
 float FireCooldown = 0;
 float HitFlash = 0;
 float Gait = 0;
 float StepClock = 0;
 void ResetOperative();
 void Interact();
 void FirePressed();
 void FireReleased();
 void Shoot();
 void Reload();
 void Pause();
 bool CanAct() const;
private:
 void Forward(float Value);
 void Right(float Value);
 void Turn(float Value);
 void Look(float Value);
 void SprintOn();
 void SprintOff();
 void AimOn();
 void AimOff();
 void CrouchOn();
 void CrouchOff();
 void JumpOn();
 void JumpOff();
};

UCLASS()
class NEONVEIL_API ANVEnemy : public ACharacter {
 GENERATED_BODY()
public:
 ANVEnemy();
 virtual void BeginPlay() override;
 virtual void Tick(float Delta) override;
 virtual float TakeDamage(float Amount, FDamageEvent const& Event, AController* Instigator, AActor* Causer) override;
 UPROPERTY(EditAnywhere) bool Rusher = false;
 UPROPERTY() USceneComponent* Visual;
 UPROPERTY() TArray<UStaticMeshComponent*> Limbs;
 UPROPERTY() UTextRenderComponent* Indicator;
 float Health = 60;
 float Clock = 0;
 float Stagger = 0;
 float DeathClock = 0;
 bool Dead = false;
 int32 AttackIndex = 0;
 enum class EState : uint8 { Chase, Windup, Recover, Stagger, Dead };
 EState State = EState::Chase;
 void Attack();
};

UCLASS()
class NEONVEIL_API ANVDistrict : public AActor {
 GENERATED_BODY()
public:
 ANVDistrict();
 virtual void BeginPlay() override;
 virtual void Tick(float Delta) override;
 UPROPERTY() UStaticMeshComponent* Gate;
 UPROPERTY() UBoxComponent* GateBlock;
 UPROPERTY() UStaticMeshComponent* RoofDoor;
 UPROPERTY() UBoxComponent* RoofBlock;
 UPROPERTY() UInstancedStaticMeshComponent* Rain;
 UPROPERTY() TArray<UAudioComponent*> Loops;
 UPROPERTY() USoundAttenuation* SpatialAudio;
 UPROPERTY() TArray<UStaticMeshComponent*> Holograms;
 UPROPERTY() TArray<ANVEnemy*> Enemies;
 UPROPERTY() UStaticMeshComponent* Drone;
 UPROPERTY() UTextRenderComponent* ObjectiveMarker;
 bool GateOpen = false;
 bool RoofOpen = false;
 float Time = 0;
 float RainClock = 0;
 FVector Broker = FVector(1750,-1120,-180);
 FVector GateTerminal = FVector(2400,-320,0);
 FVector HackTerminal = FVector(3250,-320,0);
 FVector Discovery = FVector(1250,470,0);
 FVector Extraction = FVector(3450,1480,600);
 void Build();
 void ResetDistrict();
 void SpawnSecurity();
 UStaticMeshComponent* Asset(const FString& Name, FVector Meters, FRotator Rotation = FRotator::ZeroRotator, FVector Scale = FVector::OneVector, bool Collision = true);
 UBoxComponent* Block(FVector Center, FVector Extents);
 void Sign(const FString& Text, FVector Meters, FRotator Rotation, FColor Color, float Size = 30);
 void Light(FVector Meters, FLinearColor Color, float Lumens, float Radius, bool Shadows = false);
 void Play(const FString& Name, FVector Location, float Volume = 1);
 void SetAudio(float Volume);
};

UCLASS()
class NEONVEIL_API ANVGameMode : public AGameModeBase {
 GENERATED_BODY()
public:
 ANVGameMode();
 virtual void BeginPlay() override;
 virtual void Tick(float Delta) override;
 UPROPERTY() ANVDistrict* District;
 UPROPERTY() ANVPlayer* Player;
 ENVMode Mode = ENVMode::Title;
 ENVMission Mission = ENVMission::Broker;
 int32 DialoguePage = 0;
 int32 Defeated = 0;
 int32 HackSuccess = 0;
 int32 LastHackCycle = -1;
 bool Hacking = false;
 bool FoundMemory = false;
 float HackClock = 0;
 float Elapsed = 0;
 float MessageTime = 0;
 float AudioVolume = .7f;
 int32 Quality = 2;
 FString Message;
 void StartJourney();
 void TogglePause();
 void Title();
 void SetCursor(bool Visible);
 void Interact();
 void EnemyDefeated();
 void Die();
 void Say(const FString& Text, float Duration = 6);
 FString Objective() const;
 FString Prompt() const;
 FVector Target() const;
 bool Near(FVector Position, float Range = 250) const;
 bool CanUse(FVector Position, float Range = 250) const;
 float HackPhase() const;
 void CycleQuality();
 void CycleAudio();
};

UCLASS()
class NEONVEIL_API ANVHUD : public AHUD {
 GENERATED_BODY()
public:
 virtual void DrawHUD() override;
 void Click();
private:
 struct FButton { FName Action; FBox2D Bounds; };
 TArray<FButton> Buttons;
 float SX = 1;
 float SY = 1;
 void Text(const FString& Value, float X, float Y, float Scale = 1, FLinearColor Color = FLinearColor(.8f,.9f,.9f));
 void Button(FName Action, const FString& Label, float X, float Y, float Width = 460);
};
