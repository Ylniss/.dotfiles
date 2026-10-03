import type { Register } from 'claude-code'

const goal = (scope: string) =>
  `Uruchom kolejno /shape, /polish i /clarify ${scope}, każdy na stanie po poprzednim. ` +
  'W każdym podziel analizę na subagentów i scal ich raporty, potem bez pytania zastosuj wszystkie wyniki ✓, a ✗ pomiń. ' +
  'Na końcu uruchom build i testy, jeśli repo je ma; co zepsuły zmiany, napraw lub cofnij. ' +
  'Cel spełniony, gdy każdy skill wypisał raport i listę zastosowanych ✓, build i testy przechodzą, ' +
  'a podsumowanie podaje zmiany per skill i tylko te pominięte ✗, które zasługują na decyzję użytkownika.'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'finish',
      description: 'Goal: /shape, /polish i /clarify na subagentach, stosuje wyniki ✓',
      argumentHint: '[base branch]',
    })

    return next(e)
  })

  on('command.run', { command: 'finish' }, async ($, e) => {
    const git = (...argv: string[]) => $.process.run(['git', ...argv])
    // Deferred: the host refuses $.command.run from inside a command.run hook, as it would wait on this very hook.
    const startGoal = (scope: string) => {
      $.clock.after(0, () =>
        $.command.run({ command: 'goal', args: goal(scope) }).catch(err => $.ui.toast(`/finish: ${err}`)),
      )
      return { text: `/goal: /shape → /polish → /clarify ${scope}` }
    }

    const branch = e.args.trim()
    if (!branch) {
      const status = await git('status', '--porcelain')
      if (!status.stdout.trim()) return { text: 'Drzewo czyste. Podaj branch bazowy: /finish <branch>.' }

      return startGoal('bez argumentu')
    }

    // The fork point, not the branch tip: a tip that moved on would put others' commits, reversed, into the diff.
    const mergeBase = await git('merge-base', branch, 'HEAD')
    if (mergeBase.exitCode !== 0) return { text: `Brak merge-base z ${branch}: ${mergeBase.stderr.trim()}` }

    const sha = mergeBase.stdout.trim()
    if ((await git('diff', '--quiet', sha)).exitCode === 0) return { text: `Brak zmian względem ${branch}.` }

    return startGoal(`z argumentem ${sha} (merge-base z ${branch})`)
  })
}
