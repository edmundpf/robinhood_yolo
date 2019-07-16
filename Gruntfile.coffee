module.exports = (grunt) ->
	grunt.loadNpmTasks('grunt-contrib-coffee')
	grunt.loadNpmTasks('grunt-contrib-watch')
	grunt.loadNpmTasks('grunt-contrib-copy')
	grunt.loadNpmTasks('grunt-contrib-clean')
	grunt.registerTask('sync', [
		'clean:all'
		'copy:json'
		'coffee:compile'
	])

	grunt.initConfig
		watch:
			coffee:
				files: 'src/**/*.coffee'
				tasks: ['coffee:compile']
			json:
				files: 'src/**/*.json'
				tasks: ['copy:json']

		clean:
			all: ['js/*']

		copy:
			json:
				files: [
					{
						expand: true
						cwd: 'src'
						src: '**/*.json'
						dest: 'js/'
					}
				]

		coffee:
			compile:
				options:
					bare: true
				expand: true
				flatten: false
				cwd: 'src'
				src: '**/*.coffee'
				dest: 'js/'
				ext: '.js'