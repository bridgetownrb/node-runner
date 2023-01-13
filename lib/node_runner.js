#{source}

try {
  const args = #{args}
  Promise.resolve(#{func}(...args)).then(result => {
    const output = JSON.stringify(['ok', result, []])
    process.stdout.write(output)
  })
} catch (err) {
  process.stdout.write(JSON.stringify(['err', '' + err, err.stack]))
}
