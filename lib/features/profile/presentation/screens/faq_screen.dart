import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';
import 'package:dj_tilbud_app/features/auth/domain/entities/musician_role.dart';
import 'package:lucide_icons/lucide_icons.dart';

class _FaqItem {
  const _FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

class _FaqCategory {
  const _FaqCategory(this.category, this.items);
  final String category;
  final List<_FaqItem> items;
}

// ─── DJ FAQ ───────────────────────────────────────────────────────────────────

const _djFaqData = [
  _FaqCategory('Ude hos kunden', [
    _FaqItem(
      'Skal jeg have udstyr med?',
      'Ja, dit udstyr skal som minimum omfatte pult, to højtalere og lyssetup til mængden af mennesker. Du må gerne leje udstyret hos en tredjepart, hvis ikke selv du ejer udstyret.',
    ),
    _FaqItem(
      'Kan jeg spille flere timer på aftenen?',
      'Ja, hvis kunden køber ekstra timer på aftenen, skal du meddele det til DJTILBUD. Det vil sige, at kunden ikke skal betale på selve aftenen. Vi fakturerer kunden for meromkostningen efter festen er slut, og vi udbetaler 71,5% af denne til dig. Du kan selv bestemme, hvad du tager per ekstra time på din profil.',
    ),
    _FaqItem(
      'Hvornår skal jeg stille udstyret op?',
      'Du skal stille udstyret op, så du er klar til at spille til det aftalte tidspunkt. Når du har vundet jobbet, og kontakter kunden, bør du aftale, hvornår det passer kunden bedst, at du kommer og stiller op.',
    ),
    _FaqItem(
      'Hvilke vilkår gør sig gældende for kunden?',
      'Kunden accepterer disse handelsbetingelser, når vedkommende indsender sit arrangement til DJTILBUD.',
    ),
  ]),
  _FaqCategory('Betaling', [
    _FaqItem(
      'Hvornår bliver jeg betalt?',
      'Du modtager betaling som B-honorar i begyndelsen af måneden efter jobbet er blevet afholdt. Lønperioden løber fra d. 21. til d. 20. i hver måned.\n\nEksempel 1: Hvis du spiller et job d. 20. januar, modtager du pengene d. 1. februar.\n\nEksempel 2: Hvis du derimod spiller d. 21. januar, er vi overgået til næste lønperiode, og din betaling bliver først udbetalt ved næste lønperiode, d. 1. marts.',
    ),
    _FaqItem(
      'Hvor meget tager I af den samlede pris?',
      'DJTILBUD tager 28,5% af jobbets totalpris i kommission. Du tjener 71,5% af totalprisen på jobbet. Du bestemmer også selv, hvor meget du vil tage dig betalt for jobbet.',
    ),
    _FaqItem(
      'Må jeg få betalingen kontant?',
      'Nej, du må ikke modtage betaling kontant eller ved en direkte overførsel fra kunden. Fakturering og betaling skal ske gennem DJTILBUD. Hvis kunden tilbyder kontant betaling eller direkte overførsel, skal du takke nej og henvise dem til, at de bør betale gennem DJTILBUD.',
    ),
    _FaqItem(
      'Er der nogen gebyr ved at være dj på DJTILBUD?',
      'Nej, du skal ikke betale noget gebyr for at være DJ på platformen. Vores model er en "no cure, no pay", hvilket betyder, at vi kun tager os betalt, såfremt du vinder et job - og kommer ud og spiller.',
    ),
    _FaqItem(
      'Får jeg kørselspenge?',
      'Nej, det gør du ikke. Derfor skal du inkludere din transporttid i det tilbud, du giver på et job.',
    ),
    _FaqItem(
      'Hvad gør jeg hvis kunden aflyser?',
      'Hvis kunden aflyser jobbet, skal du med det samme give os besked. Det kan du gøre på email: arthur@djtilbud.dk ved at sende en skriftlig aflysning fra kunden. Hvis det er under 7 dage før jobbet, sikrer vi dig 50% af din løn for jobbet.',
    ),
  ]),
  _FaqCategory('Budprocessen på DJTILBUD', [
    _FaqItem(
      'Kan jeg lade være med at byde på nogle jobs?',
      'Ja, du vælger selv hvilke jobs du vil byde på. Vi opfordrer dog altid vores DJs til at byde på jobs, og hvis du over en længere periode ikke har budt på nogle jobs, kontakter vi dig for at høre årsagen til det.',
    ),
    _FaqItem(
      'Hvordan ved jeg, hvad min pris skal være på et job?',
      'Kunden har mulighed for at bestemme et budget til sin fest, når de indsender et arrangement til os, som du kan byde ud fra. Hvis ikke kunden har indsendt et budget, anbefaler vi, at du byder på jobbet, hvad du normalvis vil tage for et lignende job.',
    ),
    _FaqItem(
      'Hvordan fungerer budprocessen?',
      'Når der kommer et job i den region, du spiller, modtager du en notifikation. Derfra kan du afgive dit bud på jobbet. Alt efter hvor hurtigt buddene er kommet og relevansen af dem, kan et job være åbent for tilbud op til 3 dage.',
    ),
    _FaqItem(
      'Hvad skal jeg skrive i mit tilbud?',
      'Dit tilbud skal indeholde pris, udstyr og en kort besked til kunden. Tilbuddet må ikke indeholde dit fulde navn, din Trustpilot eller andre oplysninger, der gør, at kunden kan kontakte dig direkte udenom platformen.',
    ),
    _FaqItem(
      'Hvornår ved jeg, om jeg har vundet jobbet?',
      'Du får besked på email og en push-notifikation, når du har vundet et job, derefter skal du kontakte kunden hurtigst muligt.',
    ),
  ]),
  _FaqCategory('Når du har vundet et job', [
    _FaqItem(
      'Skal jeg kontakte kunden, når jeg har vundet?',
      'Ja, du skal tage kontakt til kunden, når du har vundet jobbet. Vi foretrækker at du ringer til vedkommende - og hvis kunden ikke tager telefonen, så skriver du en SMS. Hvis du har nogle spørgsmål til kommunikation med kunder skal du skrive til os på messenger.\n\nSåfremt du ikke får svar på hverken SMS eller telefonopkald, så send en mail. Ring gerne 3-4 over et par dage. Hvis ikke du får svar, så kontakt os på messenger - så hjælper vi.\n\nHvis det er en haster eller en krisesituation så ring først på 60 55 08 22 og 6014 8698, hvis første nummer ikke svarer.',
    ),
  ]),
];

// ─── Instrumentalist FAQ ──────────────────────────────────────────────────────

const _instrumentalistFaqData = [
  _FaqCategory('Ude hos kunden', [
    _FaqItem(
      'Skal jeg have udstyr med?',
      'Du skal blot medbringe dit instrument. Lydudstyret (højttalere, mixer m.m.) håndteres af DJ\'en. Sørg for at koordinere med DJ\'en inden arrangementet, så I er enige om lydopsætning og lydcheck.',
    ),
    _FaqItem(
      'Hvornår skal jeg møde op?',
      'Du skal møde op i god tid til at varme op og lave et kort lydcheck med DJ\'en. Når du har vundet jobbet og kontakter kunden, bør du også aftale mødetidspunkt med den tilknyttede DJ, så I er koordinerede på dagen.',
    ),
    _FaqItem(
      'Kan jeg spille flere timer på aftenen?',
      'Ja, hvis kunden ønsker ekstra spilletid, skal du straks give DJTILBUD besked. Kunden betaler ikke på selve aftenen, vi fakturerer meromkostningen bagefter og udbetaler din andel til dig.',
    ),
    _FaqItem(
      'Hvad hvis jeg spiller alene uden DJ?',
      'Nogle jobs er mærket "Kun saxofonist", her spiller du solo uden en DJ. I disse tilfælde bør du afklare med kunden, om der er et lydanlæg til stede, eller om du selv skal sørge for forstærkning.',
    ),
    _FaqItem(
      'Hvilke vilkår gælder for kunden?',
      'Kunden accepterer DJTILBUD\'s handelsbetingelser, når de indsender deres arrangement.',
    ),
  ]),
  _FaqCategory('Betaling', [
    _FaqItem(
      'Hvornår bliver jeg betalt?',
      'Du modtager betaling som B-honorar i begyndelsen af måneden efter jobbet er blevet afholdt. Lønperioden løber fra d. 21. til d. 20. i hver måned.\n\nEksempel 1: Hvis du spiller et job d. 20. januar, modtager du pengene d. 1. februar.\n\nEksempel 2: Hvis du derimod spiller d. 21. januar, er vi overgået til næste lønperiode, og din betaling bliver først udbetalt ved næste lønperiode, d. 1. marts.',
    ),
    _FaqItem(
      'Hvad tjener jeg per job?',
      'Din betaling er fastsat af systemet ud fra det antal spilletimer, kunden har ønsket. Du kan se dit honorar direkte på jobkortet, inden du afgiver et tilbud. Beløbet stiger lidt, hvis du byder inden for de første dage efter jobbet er oprettet.',
    ),
    _FaqItem(
      'Må jeg modtage betaling kontant?',
      'Nej, du må ikke modtage betaling kontant eller ved direkte overførsel fra kunden. Al fakturering og betaling sker gennem DJTILBUD. Hvis kunden tilbyder kontant betaling, skal du takke nej og henvise dem til at betale via DJTILBUD.',
    ),
    _FaqItem(
      'Er der et gebyr for at være på DJTILBUD?',
      'Nej, vores model er "no cure, no pay", du betaler ingenting, medmindre du vinder et job og spiller det.',
    ),
    _FaqItem(
      'Får jeg kørselspenge?',
      'Nej. Transport er inkluderet i dit honorar, så tag afstand til jobbet i betragtning, når du vælger hvilke jobs du vil byde på.',
    ),
    _FaqItem(
      'Hvad gør jeg, hvis kunden aflyser?',
      'Giv os straks besked på arthur@djtilbud.dk med en skriftlig aflysning fra kunden. Aflyses jobbet under 7 dage før, sikrer vi dig 50% af dit honorar.',
    ),
  ]),
  _FaqCategory('Budprocessen på DJTILBUD', [
    _FaqItem(
      'Kan jeg lade være med at byde på et job?',
      'Ja, du bestemmer selv, hvilke jobs du vil byde på. Vi opfordrer dig til at byde aktivt, og kontakter dig, hvis du over længere tid ikke har afgivet nogen bud.',
    ),
    _FaqItem(
      'Hvad er min pris på et job?',
      'Prisen er fastsat af systemet og beregnes automatisk ud fra det antal spilletimer, kunden har ønsket. Du sætter ikke prisen selv, den vises direkte på jobkortet, inden du byder.',
    ),
    _FaqItem(
      'Hvordan fungerer budprocessen?',
      'Når der oprettes et job med saxofonist i din region, modtager du en push-notifikation. Du kan derefter sende et tilbud ved at skrive en personlig besked til kunden.\n\nVigtig forskel fra DJs: kun én saxofonist kan byde på hvert job. Så snart én saxofonist har afgivet et tilbud, er jobbet markeret som "Optaget" for alle andre, det gælder om at reagere hurtigt.',
    ),
    _FaqItem(
      'Hvad skal jeg skrive i mit tilbud?',
      'Skriv en personlig og engageret besked, der fortæller kunden om din erfaring og hvorfor du er det rigtige valg til deres arrangement. Undlad at oplyse dit fulde navn, direkte kontaktoplysninger eller anden information, der gør det muligt for kunden at kontakte dig uden om platformen.',
    ),
    _FaqItem(
      'Hvornår ved jeg, om jeg har vundet jobbet?',
      'Du får besked via email og push-notifikation, når du har vundet et job. Herefter skal du kontakte kunden hurtigst muligt.',
    ),
    _FaqItem(
      'Hvad er kundens særlige ønske, og kan jeg aftale en ekstra pris for det?',
      'Kunden kan tilføje et særligt ønske til musikeren, når de booker, f.eks. en bestemt sang eller et ekstra indslag. Du kan se ønsket direkte på jobbet under "Særligt ønske til musikeren", allerede inden du byder.\n\nGrundprisen er fast og beregnes ud fra antallet af spilletimer, den kan du ikke ændre. Men hvis I aftaler, at det særlige ønske koster ekstra, kan du selv forhandle beløbet med kunden og registrere det på jobbet. Vi gennemgår og bekræfter beløbet, før det lægges til den samlede pris. Kunden betaler det fulde tillæg, og du får 77% af det.',
    ),
  ]),
  _FaqCategory('Når du har vundet et job', [
    _FaqItem(
      'Skal jeg kontakte kunden, når jeg har vundet?',
      'Ja, du skal tage kontakt til kunden, når du har vundet jobbet. Vi foretrækker at du ringer til vedkommende - og hvis kunden ikke tager telefonen, så skriver du en SMS. Hvis du har nogle spørgsmål til kommunikation med kunder skal du skrive til os på messenger.\n\nSåfremt du ikke får svar på hverken SMS eller telefonopkald, så send en mail. Ring gerne 3-4 over et par dage. Hvis ikke du får svar, så kontakt os på messenger - så hjælper vi.\n\nHvis det er en haster eller en krisesituation så ring først på 60 55 08 22 og 6014 8698, hvis første nummer ikke svarer.',
    ),
  ]),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key, required this.role});

  final MusicianRole role;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    final faqData =
        role == MusicianRole.dj ? _djFaqData : _instrumentalistFaqData;

    return Scaffold(
      backgroundColor: _c.bg.canvas,
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: _c.bg.surface,
        surfaceTintColor: _c.bg.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DSSpacing.s4,
          DSSpacing.s4,
          DSSpacing.s4,
          DSSpacing.s8,
        ),
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DSSpacing.s4),
            decoration: BoxDecoration(
              color: _c.bg.surface,
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(color: _c.border.subtle),
              boxShadow: DSShadow.sm,
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.bookOpen,
                  size: 40,
                  color: _c.brand.primaryActive,
                ),
                const SizedBox(height: DSSpacing.s3),
                Text(
                  'Ofte stillede spørgsmål',
                  style: DSTextStyle.headingMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _c.text.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DSSpacing.s2),
                Text(
                  'Herunder finder du svar på de mest stillede spørgsmål. '
                  'Kan du ikke finde svar, skriv til arthur@djtilbud.dk',
                  style: DSTextStyle.labelMd.copyWith(
                    color: _c.text.secondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.s6),

          // FAQ categories
          for (final category in faqData) ...[
            Text(
              category.category,
              style: DSTextStyle.headingSm.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _c.text.primary,
              ),
            ),
            const SizedBox(height: DSSpacing.s2),
            ...category.items.map((item) => _FaqTile(item: item)),
            const SizedBox(height: DSSpacing.s6),
          ],

          // Contact CTA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DSSpacing.s4),
            decoration: BoxDecoration(
              color: _c.bg.surface,
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(color: _c.border.subtle),
              boxShadow: DSShadow.sm,
            ),
            child: Column(
              children: [
                Text(
                  'Har du stadig spørgsmål?',
                  style: DSTextStyle.headingSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _c.text.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DSSpacing.s2),
                Text(
                  'Vi sidder klar til at hjælpe.',
                  style: DSTextStyle.labelMd.copyWith(color: _c.text.secondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DSSpacing.s4),
                DSButton(
                  label: 'Kontakt os: arthur@djtilbud.dk',
                  variant: DSButtonVariant.primary,
                  onTap: () {
                    // URL launcher can be wired up when the package is available
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.item});
  final _FaqItem item;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final _c = DSTheme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: DSSpacing.s2),
        decoration: BoxDecoration(
          color: _c.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: _c.border.subtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DSSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: DSTextStyle.labelLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _c.text.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: DSSpacing.s2),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _c.brand.primaryActive,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _expanded ? LucideIcons.minus : LucideIcons.plus,
                      size: 14,
                      color: _c.brand.primaryActive,
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: DSSpacing.s3),
                Text(
                  widget.item.answer,
                  style: DSTextStyle.labelMd.copyWith(
                    color: _c.text.secondary,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
