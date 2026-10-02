import 'routine.dart';

enum ExerciseCategory { strength, cardio, mobility, stretching }

extension ExerciseCategoryLabel on ExerciseCategory {
  String get label => switch (this) {
    ExerciseCategory.strength => 'Renforcement',
    ExerciseCategory.cardio => 'Mouvement doux',
    ExerciseCategory.mobility => 'Mobilité',
    ExerciseCategory.stretching => 'Étirement',
  };
}

class ExerciseGuide {
  const ExerciseGuide({
    required this.id,
    required this.title,
    required this.category,
    required this.intro,
    required this.instructions,
    required this.easierVariant,
    required this.caution,
    required this.illustrationLabel,
    required this.sourceName,
    required this.sourceUrl,
  });

  final String id;
  final String title;
  final ExerciseCategory category;
  final String intro;
  final List<String> instructions;
  final String easierVariant;
  final String caution;
  final String illustrationLabel;
  final String sourceName;
  final String sourceUrl;

  bool get availableInRoutine =>
      exerciseCatalog.any((exercise) => exercise.id == id);
}

const exerciseGuides = <ExerciseGuide>[
  ExerciseGuide(
    id: 'plank',
    title: 'Planche',
    category: ExerciseCategory.strength,
    intro: 'Tenue sur les avant-bras, sans chercher à durer longtemps.',
    instructions: [
      'Placez les coudes sous les épaules et allongez les jambes.',
      'Soulevez le corps en gardant le tronc aligné, sans creuser le bas du dos.',
      'Respirez pendant la tenue, puis redescendez doucement.',
    ],
    easierVariant: 'Posez les genoux au sol et gardez une tenue courte.',
    caution: 'Si le bas du dos fait mal, arrêtez ce mouvement.',
    illustrationLabel: 'Schéma d’une planche sur les avant-bras.',
    sourceName: 'ACE — Front Plank',
    sourceUrl: 'https://www.acefitness.org/resources/everyone/exercise-library/32/front-plank/',
  ),
  ExerciseGuide(
    id: 'squat',
    title: 'Squats',
    category: ExerciseCategory.strength,
    intro: 'Une petite flexion des jambes, à votre amplitude.',
    instructions: [
      'Tenez-vous debout, pieds écartés comme les hanches.',
      'Pliez doucement les genoux dans une amplitude confortable, le dos droit.',
      'Remontez lentement. Une descente et une remontée font une répétition.',
    ],
    easierVariant:
        'Tenez le dossier d’une chaise stable et pliez moins les genoux.',
    caution: 'Utilisez une chaise qui ne glisse pas. Arrêtez si le mouvement provoque une douleur.',
    illustrationLabel:
        'Schéma d’une flexion légère des genoux avec appui sur une chaise.',
    sourceName: 'NHS — Strength exercises, Mini-squats',
    sourceUrl: 'https://www.nhs.uk/live-well/exercise/strength-exercises/',
  ),
  ExerciseGuide(
    id: 'step_jack',
    title: 'Jumping jack sans saut',
    category: ExerciseCategory.cardio,
    intro: 'Un pas sur le côté, sans sauter.',
    instructions: [
      'Debout, faites un pas sur le côté en levant les bras à une hauteur confortable.',
      'Ramenez le pied et les bras, puis changez de côté.',
      'Un pas et son retour font une répétition. Gardez un pied au sol.',
    ],
    easierVariant:
        'Faites le même geste assis, un bras et une jambe à la fois.',
    caution: 'Ralentissez ou arrêtez si vous êtes essoufflé au point de ne plus être à l’aise.',
    illustrationLabel:
        'Schéma d’un pas latéral avec les bras levés, sans saut.',
    sourceName: 'Leeds NHS — Jacks niveaux 1 et 2',
    sourceUrl: 'https://www.leedsth.nhs.uk/patients/resources/keeping-active-on-the-liver-transplant-list/',
  ),
  ExerciseGuide(
    id: 'wall_pushup',
    title: 'Pompes au mur',
    category: ExerciseCategory.strength,
    intro: 'Une poussée douce contre un mur stable.',
    instructions: [
      'Placez les mains à hauteur de poitrine contre le mur, à distance de bras.',
      'Pliez lentement les coudes en gardant le dos droit.',
      'Repoussez doucement le mur pour revenir au départ.',
    ],
    easierVariant:
        'Rapprochez les pieds du mur et réduisez la flexion des bras.',
    caution: 'Choisissez un mur dégagé et arrêtez en cas de douleur.',
    illustrationLabel:
        'Schéma d’une personne inclinée vers un mur, mains en appui.',
    sourceName: 'King’s College Hospital NHS — Wall press-ups',
    sourceUrl: 'https://www.kch.nhs.uk/wp-content/uploads/2024/07/4087-Spinal-surgery-Lumbar-Exercises-June-24-final-v3_FINAL.pdf',
  ),
  ExerciseGuide(
    id: 'glute_bridge',
    title: 'Pont fessier',
    category: ExerciseCategory.strength,
    intro: 'Soulevez les hanches depuis le sol, sans cambrer.',
    instructions: [
      'Allongez-vous sur le dos, genoux pliés et pieds à plat.',
      'Poussez doucement dans les pieds et soulevez les hanches.',
      'Redescendez lentement sans exagérer la cambrure du bas du dos.',
    ],
    easierVariant: 'Levez les hanches moins haut et faites une pause entre les répétitions.',
    caution: 'Arrêtez si vous ressentez une douleur dans le dos.',
    illustrationLabel:
        'Schéma d’un pont fessier, dos au sol et hanches relevées.',
    sourceName: 'ACE — Glute Bridge Exercise',
    sourceUrl: 'https://www.acefitness.org/resources/everyone/exercise-library/49/glute-bridge/',
  ),
  ExerciseGuide(
    id: 'calf_raise',
    title: 'Montées sur pointes',
    category: ExerciseCategory.strength,
    intro: 'Levez doucement les talons, avec un appui stable.',
    instructions: [
      'Posez les mains sur le dossier d’une chaise stable.',
      'Montez lentement les talons aussi haut que confortable.',
      'Redescendez avec contrôle. Une montée et une descente font une répétition.',
    ],
    easierVariant:
        'Montez les talons moins haut en gardant les deux mains en appui.',
    caution:
        'Gardez une chaise qui ne glisse pas et évitez de perdre l’équilibre.',
    illustrationLabel:
        'Schéma d’une montée sur les pointes, mains sur une chaise.',
    sourceName: 'NHS — Strength exercises, Calf raises',
    sourceUrl: 'https://www.nhs.uk/live-well/exercise/strength-exercises/',
  ),
  ExerciseGuide(
    id: 'shoulder_circle',
    title: 'Cercles d’épaules',
    category: ExerciseCategory.mobility,
    intro: 'Bougez les épaules en douceur.',
    instructions: [
      'Asseyez-vous ou tenez-vous debout, bras relâchés.',
      'Dessinez lentement un cercle avec les épaules vers l’arrière.',
      'Un cercle fait une répétition. Changez aussi de sens si cela reste confortable.',
    ],
    easierVariant: 'Faites de plus petits cercles, sans lever les bras.',
    caution:
        'Restez dans une amplitude confortable ; arrêtez si cela fait mal.',
    illustrationLabel: 'Schéma d’épaules qui effectuent un petit cercle.',
    sourceName: 'NHS — How to warm up before exercising, Shoulder rolls',
    sourceUrl: 'https://www.nhs.uk/live-well/exercise/how-to-warm-up-before-exercising/',
  ),
  ExerciseGuide(
    id: 'neck_rotation',
    title: 'Rotation douce du cou',
    category: ExerciseCategory.mobility,
    intro: 'Tournez la tête lentement, sans forcer.',
    instructions: [
      'Asseyez-vous droit, épaules relâchées, regard devant vous.',
      'Tournez doucement la tête vers la gauche, revenez au centre, puis vers la droite.',
      'Le trajet gauche puis droite fait une répétition.',
    ],
    easierVariant:
        'Tournez moins loin, uniquement jusqu’à une position confortable.',
    caution:
        'Ne forcez pas et arrêtez si le mouvement provoque douleur ou vertige.',
    illustrationLabel:
        'Schéma d’une tête qui tourne doucement de gauche à droite.',
    sourceName: 'NHS — Flexibility exercises, Neck rotation',
    sourceUrl: 'https://www.nhs.uk/live-well/exercise/flexibility-exercises/',
  ),
  ExerciseGuide(
    id: 'calf_stretch',
    title: 'Étirement du mollet',
    category: ExerciseCategory.stretching,
    intro: 'Un étirement doux, pied arrière au sol.',
    instructions: [
      'Placez les mains contre un mur et reculez une jambe.',
      'Gardez le talon arrière au sol et avancez doucement le poids du corps.',
      'Restez dans une sensation confortable, puis changez de jambe.',
    ],
    easierVariant: 'Rapprochez le pied arrière pour réduire l’étirement.',
    caution: 'Ne forcez pas l’étirement et arrêtez si une douleur apparaît.',
    illustrationLabel: 'Schéma d’un étirement du mollet, mains contre un mur.',
    sourceName: 'NHS — Flexibility exercises, Calf stretch',
    sourceUrl: 'https://www.nhs.uk/live-well/exercise/flexibility-exercises/',
  ),
];

ExerciseGuide guideById(String id) => exerciseGuides.firstWhere(
  (guide) => guide.id == id,
  orElse: () => throw FormatException('Fiche inconnue : $id'),
);
