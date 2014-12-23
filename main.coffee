# Deps

autoprefixer = require('autoprefixer-core')
{css, utils} = require 'octopus-helpers'
{_} = utils


# Private fns

_declaration = ($, vendorPrefixes, prefixer, property, value, modifier) ->
  return unless value
  value = modifier(value) if modifier
  return prefixer(property, value) if vendorPrefixes
  $ "#{property}: #{value};"


_comment = ($, addExplainingCommentsToCSS, text) ->
  return unless addExplainingCommentsToCSS
  $ "/* #{text} */"


defineVariable = (name, value, options) ->
  # TODO: add :root selector when selectorOptions is enabled
  "--#{name}: #{value};"


renderVariable = (name) -> name


_startSelector = ($, selector, selectorOptions, text) ->
  return unless selector
  $ '%s%s', utils.prettySelectors(text, selectorOptions), ' {'


_endSelector = ($, selector) ->
  return unless selector
  $ '}'


autoprefixedOpt = null

_initAutoprefixer = (prefixOptions = {}) ->
  try
    autoprefixedOpt = autoprefixer(prefixOptions)
  catch e
    'Parse error – try to check the syntax'


_prefixed = ($, prefixOptions, property, value) ->
  _initAutoprefixer() unless autoprefixedOpt

  output = "#{property}: #{value}"
  prefixed = autoprefixedOpt.process(output)
  children = prefixed.root.childs
  $ "#{child.prop}: #{child.value};" for child in children


class CSS

  render: ($) ->
    $$ = $.indents
    prefixed = _.partial(_prefixed, $$, {})
    declaration = _.partial(_declaration, $$, @options.vendorPrefixes, prefixed)
    comment = _.partial(_comment, $, @options.addExplainingCommentsToCSS)
    unit = _.partial(css.unit, @options.unit)
    convertColor = _.partial(css.convertColor, null, @options)
    fontStyles = _.partial(css.fontStyles, declaration, convertColor, unit, @options.quoteType)

    selectorOptions =
      separator: @options.selectorTextStyle
      selector: @options.selectorType
      maxWords: 3
      fallbackSelectorPrefix: 'layer'
    startSelector = _.partial(_startSelector, $, @options.selector, selectorOptions)
    endSelector = _.partial(_endSelector, $, @options.selector)

    if @type == 'textLayer'
      for textStyle in css.prepareTextStyles(@options.inheritFontStyles, @baseTextStyle, @textStyles)

        comment(css.textSnippet(@text, textStyle))

        if @options.selector
          if textStyle.ranges
            selectorText = utils.textFromRange(@text, textStyle.ranges[0])
          else
            selectorText = @name

          startSelector(selectorText)

        if not @options.inheritFontStyles or textStyle.base
          if @options.showAbsolutePositions
            declaration('position', 'absolute')
            declaration('left', @bounds.left, unit)
            declaration('top', @bounds.top, unit)

          if @bounds
            declaration('width', unit(@bounds.width))
            declaration('height', unit(@bounds.height))

          declaration('opacity', @opacity)

          if @shadows
            declaration('text-shadow', css.convertTextShadows(convertColor, unit, @shadows))

        fontStyles(textStyle)

        endSelector()
        $.newline()
    else
      comment("Style for \"#{utils.trim(@name)}\"")
      startSelector(@name)

      if @options.showAbsolutePositions
        declaration('position', 'absolute')
        declaration('left', @bounds.left, unit)
        declaration('top', @bounds.top, unit)

      if @bounds
        declaration('width', unit(@bounds.width))
        declaration('height', unit(@bounds.height))

      declaration('opacity', @opacity)

      if @background
        declaration('background-color', @background.color, convertColor)

        if @background.gradient
          declaration('background-image', css.convertGradients(convertColor, {gradient: @background.gradient, @bounds}))

      if @borders
        border = @borders[0]
        declaration('border', "#{unit(border.width)} #{border.style} #{convertColor(border.color)}")

      declaration('border-radius', @radius, css.radius)

      if @shadows
        declaration('box-shadow', css.convertShadows(convertColor, unit, @shadows))

      endSelector()


module.exports = {defineVariable, renderVariable, renderClass: CSS}
