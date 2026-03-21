export function ProfilePanel() {
  return (
    <div className="pageStack">
      <section className="profileHero">
        <div className="profileAvatar">👤</div>
        <div className="profileHeroCopy">
          <strong>PetFit Member</strong>
          <span>Set up your account details</span>
          <div className="profilePill">Account Ready</div>
        </div>
      </section>

      <section className="statsCard">
        <div>
          <strong>12</strong>
          <span>Orders</span>
        </div>
        <div>
          <strong>28</strong>
          <span>Favorites</span>
        </div>
        <div>
          <strong>3</strong>
          <span>Reviews</span>
        </div>
      </section>

      <section className="menuCard">
        <div className="menuTile">
          <span className="menuIcon accent">👤</span>
          <span>Edit Profile</span>
          <em>Coming Soon</em>
        </div>
        <div className="menuTile">
          <span className="menuIcon accent">⌂</span>
          <span>Addresses</span>
          <em>Coming Soon</em>
        </div>
        <div className="menuTile">
          <span className="menuIcon accent">◫</span>
          <span>Payment Methods</span>
          <em>Coming Soon</em>
        </div>
        <div className="menuTile">
          <span className="menuIcon accent">♡</span>
          <span>Saved Looks</span>
          <em>Coming Soon</em>
        </div>
      </section>

      <section className="menuCard">
        <div className="menuTile">
          <span className="menuIcon">?</span>
          <span>Help Center</span>
          <em>Coming Soon</em>
        </div>
        <div className="menuTile">
          <span className="menuIcon">⚙</span>
          <span>Preferences</span>
          <em>Coming Soon</em>
        </div>
      </section>
    </div>
  );
}
