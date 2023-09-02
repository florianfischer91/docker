# converts a bashbrew architecture to apt's strings
def aptArch:
	{
		# https://dl-cdn.alpinelinux.org/alpine/edge/main/
		# https://wiki.alpinelinux.org/wiki/Architecture#Alpine_Hardware_Architecture_.28.22arch.22.29_Support
		# https://pkgs.alpinelinux.org/packages ("Arch" dropdown)
		amd64: "x86_64",	
	}[.]
	;

# RUN set -eux; \
# 	...
# 	{{
# 		download({
# 			arches: .arches,
# 			urlKey: "dockerUrl",
# 			#sha256Key: "sha256",
# 			target: "docker.tgz",
# 			#missingArchWarning: true,
# 		})
# 	}}; \
# 	...
def download(opts):
	(opts.sha256Key | not) as $notSha256
	| [
	"aptArch=\"$(uname -m)\";
	case \"$aptArch\" in"
		,
		(
		opts.arches | to_entries[]
		| .key as $bashbrewArch
		| ($bashbrewArch | aptArch) as $aptArch
		| .value
		| .[opts.urlKey] as $url
		| (if $notSha256 then "none" else .[opts.sha256Key] end) as $sha256
		| select($aptArch and $url and $sha256)
		| ("
		\($aptArch | @sh))
			url=\($url | @sh);"
			+ if $notSha256 then "" else "
			sha256=\($sha256 | @sh);"
			end + "
			;;"
			)
		)
		,
		"
		*) echo >&2 \"\(if opts.missingArchWarning then "warning" else "error" end): unsupported \(opts.target | @sh) architecture ($aptArch)\(if opts.missingArchWarning then "; skipping" else "" end)\"; exit \(if opts.missingArchWarning then 0 else 1 end) ;;
	esac;
	
	wget -O \(opts.target | @sh) \"$url\";"
	,
	if $notSha256 then "" else "
	echo \"$sha256 *\"\(opts.target | @sh) | sha256sum -c -;"
	end
	] | add
	| rtrimstr(";")
	| gsub("(?<=[^[:space:]])\n"; " \\\n")
	| gsub("(?<=[[:space:]])\n"; "\\\n")
	;
