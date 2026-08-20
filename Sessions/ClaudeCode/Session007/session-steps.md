Playwright: https://github.com/microsoft/playwright-cli
- Install playwright globally: `npm install -g @playwright/cli@latest`
- Install playwright skills: `playwright-cli install --skills`
- Test playwright command `playwright-cli --help`
- Test playwright from Claude: `Using the playwright-cli, open my default salesforce org (cws) in a headed session`

Hyperframes: https://hyperframes.heygen.com/
- Install: `npx skills add heygen-com/hyperframes --full-depth`

Simple circle demo:
`I would like to create a new video using /hyperframes for the purpose of learning the tool. Let's start simple with a single scene that has a sky blue background with a red circle on the left that will move all the way to the right over the span of 5 seconds. We can call this demonstration video simple-circle`

`This looks great, now, let's keep the cirlce in place for 2 seconds, fade it's color to blue, then move back to the left, i.e. it's starting position`

`Let's add a captions bar at the bottom that is explaining what's happening at each step`

`Can we add a basic voice-over track as well that reads the captions?`

Salesforce Support Video
`I want to create support documentation for salesforce users that walks them through how to create a new contact on an account. Open my default salesforce org using the playwright-cli, and capture screenshots of every step that takes then from the home screen, to an account, to the related tab, new contact button, etc. Let's capture every change in state so that we can use these screenshots in a future support video or annimation. Make up some test data for the contact. Place all screenshots in the videos/create-account-contact/assets directory (create it if you need to). Make sure not to capture tooltips of other popups.`

`Using these screenshots, let's create a support video using /hyperframes. Let's take inspiration from the simple-circle video where we use a captions bar at the bottom and a voiceover that walks through the steps.`

`My team are highly visual learners... could we add a mouse pointer, hand, or some kind of highlight that will visually show what's being talked about? For example, when we tell the user to click on the Related tab, it would be cool if that's highlighted somehow in the video.`