import 'package:flutter/material.dart';
import 'package:onboarding/onboarding.dart';
import 'package:social_media_app/global_files.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late Material materialButton;
  late int index;
  late List<PageModel> onboardingPagesList;

  @override
  void initState() {
    super.initState();
    onboardingPagesList = [
      pageModelWidget('assets/images/onboarding/page1.jpg', 'MAKE FRIENDS'),
      pageModelWidget('assets/images/onboarding/page2.jpg', 'SHARE YOUR THOUGHTS'),
      pageModelWidget('assets/images/onboarding/page3.jpg', 'CHAT EASILY WITH OTHERS')
    ];
    materialButton = _skipButton();
    index = 0;
    sharedPreferencesController.setOnboardingDisplayed(true);
  }

  Widget dummyParagraphWidget = Padding(
    padding: const EdgeInsets.symmetric(horizontal: 45.0, vertical: 10.0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        dummyText,
        style: pageInfoStyle,
        textAlign: TextAlign.left,
      ),
    ),
  );

  PageModel pageModelWidget(
    String imageUrl,
    String title,
  ){
    return PageModel(
      widget: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            width: 0.0,
            color: background,
          ),
        ),
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 45.0,
                  vertical: 90.0,
                ),
                child: Image.asset(imageUrl, color: pageImageColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: pageTitleStyle,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              for(int i = 0; i < 3; i++)
              dummyParagraphWidget
            ],
          ),
        ),
      ),
    );
  }

  Material _skipButton({void Function(int)? setIndex}) {
    return Material(
      borderRadius: defaultSkipButtonBorderRadius,
      color: defaultSkipButtonColor,
      child: InkWell(
        borderRadius: defaultSkipButtonBorderRadius,
        onTap: () {
          if (setIndex != null) {
            index = 2;
            setIndex(2);
          }
        },
        child: const Padding(
          padding: defaultSkipButtonPadding,
          child: Text(
            'Skip',
            style: defaultSkipButtonTextStyle,
          ),
        ),
      ),
    );
  }

  Material get _enterHomePage {
    return Material(
      borderRadius: defaultProceedButtonBorderRadius,
      color: defaultProceedButtonColor,
      child: InkWell(
        borderRadius: defaultProceedButtonBorderRadius,
        onTap: () {
          Navigator.push(
            context,
            SliderRightToLeftRoute(
              page: const HomePage()
            )
          );
        },
        child: const Padding(
          padding: defaultProceedButtonPadding,
          child: Text(
            'Continue',
            style: defaultProceedButtonTextStyle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Onboarding(
        pages: onboardingPagesList,
        onPageChange: (int pageIndex) {
          index = pageIndex;
        },
        startPageIndex: 0,
        footerBuilder: (context, dragDistance, pagesLength, setIndex) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              border: Border.all(
                width: 0.0,
                color: background,
              ),
            ),
            child: ColoredBox(
              color: background,
              child: Padding(
                padding: const EdgeInsets.all(45.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomIndicator(
                      netDragPercent: dragDistance,
                      pagesLength: pagesLength,
                      indicator: Indicator(
                        indicatorDesign: IndicatorDesign.line(
                          lineDesign: LineDesign(
                            lineType: DesignType.line_uniform,
                          ),
                        ),
                      ),
                    ),
                    index == pagesLength - 1
                        ? _enterHomePage
                        : _skipButton(setIndex: setIndex)
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}