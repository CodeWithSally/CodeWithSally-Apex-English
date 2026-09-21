const { Marp } = require('@marp-team/marp-core')

function wrapCodeLines(html) {
  const lines = html.replace(/\n$/, '').split('\n')
  const openTags = []
  return lines
    .map((line, index) => {
      const leading = openTags.join('')
      const tagRe = /<\/?span\b[^>]*>/g
      let match
      while ((match = tagRe.exec(line))) {
        if (match[0].startsWith('</')) {
          openTags.pop()
        } else {
          openTags.push(match[0])
        }
      }
      const trailing = openTags
        .slice()
        .reverse()
        .map(() => '</span>')
        .join('')
      const visible = line.replace(/<[^>]+>/g, '')
      const body = visible.length === 0 ? `${line}&nbsp;` : line
      return `<span class="code-line"><span class="code-ln">${index + 1}</span><span class="code-src">${leading}${body}${trailing}</span></span>`
    })
    .join('')
}

function registerApex(hljs) {
  if (hljs.getLanguage('apex')) {
    return
  }
  // dist/apex.min.js is an IIFE that calls hljs.registerLanguage on globalThis.hljs.
  // Marp server/watch creates a new highlighter per request; Node's require cache
  // would otherwise register Apex only on the first instance, so later reloads
  // emit unhighlighted ```apex fences.
  const previous = globalThis.hljs
  globalThis.hljs = hljs
  const apexPath = require.resolve('highlightjs-apex/dist/apex.min.js')
  delete require.cache[apexPath]
  require(apexPath)
  globalThis.hljs = previous
}

module.exports = function engine(opts) {
  const marp = new Marp(opts)
  registerApex(marp.highlightjs)

  // Keep fences at the CSS font-size; Marp's downscale-only wrapper
  // otherwise leaves a tall empty pane with tiny type.
  const origFence = marp.markdown.renderer.rules.fence
  if (origFence) {
    marp.markdown.renderer.rules.fence = (...args) =>
      origFence(...args)
        .replace(/\sdata-auto-scaling="downscale-only"/g, '')
        .replace(/ is="marp-pre"/g, '')
        .replace(/(<pre\b)([^>]*>)/, '$1 class="has-line-numbers"$2')
        .replace(/(<code[^>]*>)([\s\S]*?)(<\/code>)/, (_, open, body, close) => {
          return `${open}${wrapCodeLines(body)}${close}`
        })
  }

  return marp
}
