import type { Register } from 'claude-code'

type FinishConfig = { skills: string[]; rules: string }

const listed = (commands: string[]) => new Intl.ListFormat('pl').format(commands)

const goal = ({ skills, rules }: FinishConfig, scope: string) =>
  `Uruchom kolejno ${listed(skills.map(s => `/${s}`))} ${scope}. ${rules} ` +
  'Każdy skill działa na stanie po poprzednim. W każdym skillu podziel analizę na subagentów i scal ich raporty. ' +
  'Podsumowanie podaje zmiany per skill i tylko te pominięte ✗, które zasługują na decyzję użytkownika. ' +
  'Cel spełniony, gdy każdy skill wypisał raport i listę zastosowanych ✓, build i testy przechodzą, a podsumowanie jest gotowe.'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'finish',
      description: 'Goal: skille przeglądu z finish.json na subagentach, stosuje wyniki ✓',
      argumentHint: '[base branch]',
    })

    return next(e)
  })

  on('command.run', { command: 'finish' }, async ($, e) => {
    const git = (...argv: string[]) => $.process.run(['git', ...argv])
    const startGoal = async (scope: string) => {
      const finish: FinishConfig = JSON.parse(await $.fs.read(`${$.plugin.root}/finish.json`))
      // Deferred: the host refuses $.command.run from inside a command.run hook, as it would wait on this very hook.
      $.clock.after(0, () =>
        $.command.run({ command: 'goal', args: goal(finish, scope) }).catch(err => $.ui.toast(`/finish: ${err}`)),
      )
      return { text: `/goal: ${finish.skills.map(s => `/${s}`).join(' → ')} ${scope}` }
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
