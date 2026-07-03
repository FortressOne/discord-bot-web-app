# Mints and verifies QWTF-Live-style login tokens: "username:id:foid:digest".
# The digest is the first 10 hex chars of SHA1(salt + username + id + foid),
# matching MakeLoginCookie in server-qwprogs ssqc/login.qc. The salt here must
# be the same LOGIN_SALT the progs were compiled with.
module TflToken
  DIGEST_LENGTH = 10

  def self.salt
    ENV["TFL_LOGIN_SALT"].presence or
      raise KeyError, "TFL_LOGIN_SALT is not set; it must match the progs' compile-time LOGIN_SALT"
  end

  def self.mint(player)
    username = sanitize_username(player.name)
    id = player.id.to_s
    foid = player.id.to_s
    "#{username}:#{id}:#{foid}:#{digest(username, id, foid)}"
  end

  # Returns { username:, id:, foid: } for a valid token, nil otherwise.
  def self.verify(token)
    username, id, foid, dig, extra = token.to_s.split(":")
    return nil if extra || [username, id, foid, dig].any?(&:blank?)
    return nil unless ActiveSupport::SecurityUtils.secure_compare(dig, digest(username, id, foid))

    { username: username, id: id, foid: foid }
  end

  def self.digest(username, id, foid)
    Digest::SHA1.hexdigest("#{salt}#{username}#{id}#{foid}")[0, DIGEST_LENGTH]
  end

  # Colons and whitespace would corrupt the token's field separators when the
  # progs tokenize it.
  def self.sanitize_username(name)
    name.to_s.gsub(/[:\s]+/, "_")
  end
end
