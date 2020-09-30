import 'dart:async';

import 'package:challenge/components/SearchEntityTile.dart';
import 'package:challenge/constants.dart';
import 'package:challenge/models/searchEntity.dart';
import 'package:flutter/material.dart';

/// if T is Map<T, E>, E should implement SearchEntity
typedef QueryCallback = Future<List<dynamic>> Function(String query);
typedef OnFocusChangedCallback = void Function(bool onFocus);

typedef ItemBuilder = Function(BuildContext context, int index);

class ASearchBar extends StatefulWidget {
  /* style */
  /// The color used for elements such as the progress indicator. Defaults to
  /// the themes accent color if not specified
  final Color accentColor;

  /// The color of the card. If not specified, defaults to theme.cardColor
  final Color backgroundColor;

  /// When specified, overrides the themes icon color
  final Color iconColor;

  /// The TextStyle for the hint in the TextField.
  final TextStyle hintStyle;

  /// The TextStyle for the text input of the ASearchBar.
  final TextStyle queryStyle;

  /* config */

  /// A double that will determine the distance between the ASearchBar and its
  /// dropdown card. Defaults to 5.0
  final double dropdownGap;

  /// A double that will determine the dropdown card elevation. Defaults to 6.0
  final double dropdownElevation;

  /// A double that will determine the card max height
  final double dropdownHeight;

  /// A double that will determine the card max width.The default card width
  /// will be the same width of the ASearchBar widget
  final double dropdownWidth;

  /// The shape of the dropdown card. Default shape will be a rounded rectangle
  /// with 8.0 of radius
  final ShapeBorder dropdownShape;

  /// The text value of the hint of the TextField.
  final String hint;

  /// The progress of the LinearProgressIndicator on the bottom of the ASearchBar.
  /// When set to a double between 0..1, will show show a determined
  /// LinearProgressIndicator. When set to true, the FloatingSearchBar
  /// will show an indetermined LinearProgressIndicator. When false, will hide
  /// the LinearProgressIndicator.
  final dynamic progress;

  /// The duration of the animation between opened and closed state.
  final Duration transitionDuration;

  /// The delay between the time the user stopped typing and the invocation
  /// of the onQueryChanged callback. This is useful for example if you want
  /// to avoid doing expensive tasks, such as making a network call,
  /// for every single character. Defaults to 300 (milisseconds).
  final Duration debounceDelay;

  /// The curve for the animation between opened and closed state.
  final Curve transitionCurve;

  /// The transition to be used for animating between closed and opened state.
  final Animation transition;

  /// Will override the theme definition for the ASearchBar textfield.
  final InputDecoration inputDecorator;

  /* utility */

  /// A callback that gets invoked when the input of the query inside the
  /// TextField changed. A Future that will expect a List<T> that will be
  /// used by its default itemBuilder and also sent as parameter on the
  /// itemBuilder callback. If T is not a Map, then itemBuilder callback
  /// must be specified.
  final QueryCallback onQueryChanged;

  /// A callback that gets invoked when the user submitted their query
  /// (e.g. hit the search button). A Future that will expect a List<T>
  /// that will be used by its default itemBuilder and also sent as parameter
  /// on the itemBuilder callback. If T is not a Map, then itemBuilder callback
  /// must be specified.
  final QueryCallback onSubmited;

  /// A callback that gets invoked when the ASearchBar receives or looses focus.
  final OnFocusChangedCallback onFocusChanged;

  /// The builder that will be called for each item of the search result,
  /// equivalent to the listview itemBuilder. If not specified each item will
  /// show a simple listtile with an avatar on the leading, title, subtitle.
  /// The search result must provide this map fields. Avatar is optional.
  final ItemBuilder itemBuilder;

  /// The controller for this ASearchBar which can be used to programatically
  /// open, close, show or hide the ASearchBar, set or clear any text.
  final TextEditingController controller;

  ASearchBar({
    this.accentColor,
    this.backgroundColor,
    this.iconColor,
    this.hintStyle,
    this.queryStyle,
    this.dropdownGap = 5.0,
    this.dropdownElevation = 6.0,
    this.dropdownHeight,
    this.dropdownWidth = double.infinity,
    this.dropdownShape,
    this.hint,
    this.progress = 0.0,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.debounceDelay = const Duration(milliseconds: 300),
    this.transitionCurve,
    this.transition,
    this.inputDecorator,
    @required this.controller,
    this.itemBuilder,
    this.onQueryChanged,
    this.onSubmited,
    this.onFocusChanged,
  }) : assert(progress == null || (progress is num || progress is bool));

  @override
  ASearchBarState createState() => ASearchBarState();
}

class ASearchBarState extends State<ASearchBar>
    with SingleTickerProviderStateMixin {
  /// widgets
  Widget entityListView;

  /// entities
  Map<dynamic, SearchEntity> entitiesMap;

  /// controllers
  AnimationController animationController;
  Animation animation;

  /// internal
  OverlayEntry overlayEntry;
  OverlayState overlayState;
  FocusNode focus;
  Timer debounce;
  Offset offset;

  bool isDropdownOpen;

  @override
  void initState() {
    super.initState();

    focus = new FocusNode();

    animationController = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );

    isDropdownOpen = false;
  }

  @override
  void dispose() {
    debounce.cancel();

    animationController.reverse();
    isDropdownOpen = false;

    super.dispose();
  }

  /// Creates a debounce function for calling onQueryChanged
  void handleOnChange(String text) {
    if (debounce?.isActive ?? false) debounce.cancel();
    debounce = Timer(
      widget.controller.text.isEmpty ? Duration.zero : widget.debounceDelay,
      () async {
        if (widget.onQueryChanged != null) {
          final callbackResult = await widget.onQueryChanged(text);
          if (callbackResult != null) updateDropdownData(callbackResult);
        }
      },
    );
  }

  /// Updates dropdown and submit callback
  Future<void> handleSubmit() async {
    if (widget.onSubmited != null) {
      final callbackResult = await widget.onSubmited(widget.controller.text);
      if (callbackResult != null) updateDropdownData(callbackResult);
    }
  }

  /// Changes overlay state based on TextField focus
  void handleOverlayFocusOut(bool focus) {
    if (!focus) {
      // A timer is used to allow the closing animation to happen
      Timer(widget.transitionDuration, () {
        if (isDropdownOpen) {
          overlayEntry.remove();
          isDropdownOpen = !isDropdownOpen;
        }
      });
      animationController.reverse();
    }
  }

  /// Notifies focus for callbacks and internal handlers
  void handleFocusChange(bool onFocus) {
    handleOverlayFocusOut(onFocus);
    widget.onFocusChanged?.call(onFocus); // only calls if defined
  }

  /// Checks data returned from the callbacks
  void updateDropdownData(List<dynamic> data) {
    if (data is List<Map>) {
      /// SearchEntity enforces basic attributes for rendering without itemBuilder
      if (data[0] is Map<dynamic, SearchEntity>) {
        overlayState.setState(() {
          entitiesMap = data[0];
          entityListView = buildQueryListView();
        });
      }
    } else {
      overlayState.setState(() {
        entitiesMap = data[0];
        // TODO: use itemBuilder
      });
    }

    if (!animationController.isCompleted) animationController.forward();
  }

  /// Collects position data for the overlay based on TextField position
  void getDropdownData(BuildContext context) {
    RenderBox renderBox = context.findRenderObject();
    offset = renderBox.localToGlobal(Offset.zero);

    overlayState = Overlay.of(context);

    /// checks maximum width against searchbar actual width
    final overlayWidth = renderBox.size.width > widget.dropdownWidth
        ? widget.dropdownWidth
        : renderBox.size.width;

    animation = Tween(begin: 0.0, end: overlayWidth).animate(
      CurvedAnimation(
          parent: animationController,
          curve: widget.transitionCurve ?? Curves.fastOutSlowIn),
    );
  }

  /// Creates an overlay based on the TextField position
  OverlayEntry createOverlay(BuildContext context) {
    return OverlayEntry(
        builder: (context) => Positioned(
              top: offset.dy + kDefaultSearchBarSize + widget.dropdownGap,
              child: AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  final size = animation.value;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
                    width: size,
                    height: size / 2,
                    child: Card(
                      child: entityListView,
                      elevation: widget.dropdownElevation,
                      shape: widget.dropdownShape ??
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                    ),
                  );
                },
              ),
            ));
  }

  /// Referenced from: FloatingSearchAppBar._buildProgressBar
  /// https://pub.dev/packages/material_floating_search_bar
  Widget buildProgressBar() {
    final progress = widget.progress;
    const progressBarHeight = 2.75;

    final progressBarColor =
        widget.accentColor ?? Theme.of(context).accentColor;
    final showProgresBar = progress != null &&
        (progress is num || (progress is bool && progress == true));
    final progressValue =
        progress is num ? progress.toDouble().clamp(0.0, 1.0) : null;

    return AnimatedOpacity(
      opacity: showProgresBar ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: SizedBox(
        height: progressBarHeight,
        child: LinearProgressIndicator(
          value: progressValue,
          semanticsValue: progressValue?.toStringAsFixed(2),
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation(progressBarColor),
        ),
      ),
    );
  }

  /// Creates a ListView based on the data received from the callbacks
  Widget buildQueryListView() {
    /// TODO: ListTile gives errors when used on a dynamic sized container.
    /// Change SearchEntityTile implementation to a custom Widget
    return ListView.builder(
      itemCount: entitiesMap.length,
      itemBuilder: widget.itemBuilder ??
          (ctx, index) => SearchEntityTile(
                entitiesMap.values.elementAt(index),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kDefaultSearchBarSize,
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: kDefaultPadding),
      padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultRadius),
        boxShadow: [kDefaultShadow],
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            children: [
              Expanded(
                child: FocusScope(
                  child: Focus(
                    onFocusChange: handleFocusChange,
                    child: TextField(
                      onTap: () {
                        setState(() {
                          if (!isDropdownOpen) {
                            getDropdownData(context);
                            overlayEntry = createOverlay(context);
                            overlayState.insert(overlayEntry);
                          }

                          isDropdownOpen = !isDropdownOpen;
                        });
                      },
                      focusNode: focus,
                      controller: widget.controller,
                      onChanged: handleOnChange,
                      style: widget.queryStyle,
                      decoration: widget.inputDecorator ??
                          InputDecoration(
                            hintText: widget.hint ?? "Search",
                            hintStyle: widget.hintStyle ??
                                TextStyle(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(kDefaultTransparency),
                                ),
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: widget.iconColor ?? Theme.of(context).iconTheme.color,
                ),
                onPressed: handleSubmit,
              )
            ],
          ),
          buildProgressBar(),
        ],
      ),
    );
  }
}
