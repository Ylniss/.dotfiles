import { expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On, ProcessRunResult } from 'claude-code'

const SHA = 'abc123'

const finish = ($: Engine, args: string) =>
  $.command.run({
    command: 'finish',
    args,
    origin: { kind: 'composer' },
    presentation: { isFullscreen: false, columns: 120 },
  })

const ran = (exitCode: number, stdout = '', stderr = ''): ProcessRunResult => ({
  exitCode,
  stdout,
  stderr,
  isStdoutTruncated: false,
  isStderrTruncated: false,
})

const fakeGit = (on: On, answers: Record<string, ProcessRunResult>) =>
  on('process.run', async (_$, e) => {
    const value = answers[e.argv.slice(1, 3).join(' ')]
    if (!value) throw new Error(`unexpected git ${e.argv.join(' ')}`)
    return { value }
  })

const goalRuns = (on: On) => {
  const args: string[] = []
  on('command.run', { command: 'goal' }, async (_$, e) => {
    args.push(e.args)
    return { text: '' }
  })
  return args
}

test('starts the goal on the merge-base with the branch', async ($, on) => {
  const clock = mock.clock(on)
  fakeGit(on, { 'merge-base develop': ran(0, `${SHA}\n`), 'diff --quiet': ran(1) })
  const goals = goalRuns(on)

  const { text } = await finish($, 'develop')
  await clock.settle()

  expect(text).toContain(SHA)
  expect(goals).toEqual([expect.stringContaining(`/clarify z argumentem ${SHA} (merge-base z develop)`)])
})

test('starts the goal on the working tree without a branch', async ($, on) => {
  const clock = mock.clock(on)
  fakeGit(on, { 'status --porcelain': ran(0, ' M a.ts\n') })
  const goals = goalRuns(on)

  await finish($, '')
  await clock.settle()

  expect(goals).toEqual([expect.stringContaining('/clarify bez argumentu')])
})

test('refuses a clean tree without a branch', async ($, on) => {
  const clock = mock.clock(on)
  fakeGit(on, { 'status --porcelain': ran(0) })
  const goals = goalRuns(on)

  const { text } = await finish($, '')
  await clock.settle()

  expect(text).toContain('Drzewo czyste')
  expect(goals).toHaveLength(0)
})

test('refuses a branch with no changes', async ($, on) => {
  fakeGit(on, { 'merge-base develop': ran(0, `${SHA}\n`), 'diff --quiet': ran(0) })

  const { text } = await finish($, 'develop')

  expect(text).toContain('Brak zmian')
})

test('reports an unknown branch', async ($, on) => {
  fakeGit(on, { 'merge-base nope': ran(128, '', 'fatal: Not a valid object name nope') })

  const { text } = await finish($, 'nope')

  expect(text).toContain('Brak merge-base z nope')
})
