
import os
from flask import Flask, render_template, redirect, url_for, request, flash, abort
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, SelectField
from wtforms.validators import InputRequired, Email, Length, EqualTo
from dotenv import load_dotenv
from urllib.parse import urlparse

load_dotenv()

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
    db_url = os.getenv('DATABASE_URL')
    if db_url:
        # Render & others might give postgres://; SQLAlchemy needs postgresql://
        if db_url.startswith("postgres://"):
            db_url = db_url.replace("postgres://", "postgresql://", 1)
        app.config['SQLALCHEMY_DATABASE_URI'] = db_url
    else:
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///app.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    return app

app = create_app()
db = SQLAlchemy(app)
with app.app_context():
    db.create_all()

login_manager = LoginManager(app)
login_manager.login_view = "login"

BRANCHES = ["CS", "IT", "ME", "ECE", "EE", "CE"]

class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)

    students = db.relationship("Student", backref="owner", lazy=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
 
class Student(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    roll_number = db.Column(db.String(50), nullable=False)
    name = db.Column(db.String(200), nullable=False)
    branch = db.Column(db.String(10), nullable=False)
    email = db.Column(db.String(255), nullable=True)
    phone = db.Column(db.String(50), nullable=True)

    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)

    __table_args__ = (db.UniqueConstraint('roll_number', 'user_id', name='uix_roll_user'),)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# --- Forms ---
class SignupForm(FlaskForm):
    email = StringField("Email", validators=[InputRequired(), Email(), Length(max=255)])
    password = PasswordField("Password", validators=[InputRequired(), Length(min=6)])
    confirm = PasswordField("Confirm Password", validators=[InputRequired(), EqualTo("password")])
    submit = SubmitField("Create account")

class LoginForm(FlaskForm):
    email = StringField("Email", validators=[InputRequired(), Email(), Length(max=255)])
    password = PasswordField("Password", validators=[InputRequired(), Length(min=6)])
    submit = SubmitField("Log in")

class StudentForm(FlaskForm):
    roll_number = StringField("Roll Number", validators=[InputRequired(), Length(max=50)])
    name = StringField("Name", validators=[InputRequired(), Length(max=200)])
    branch = SelectField("Branch", choices=[(b, b) for b in BRANCHES])
    email = StringField("Email (optional)", validators=[Length(max=255)])
    phone = StringField("Phone (optional)", validators=[Length(max=50)])
    submit = SubmitField("Save")

# --- CLI helper ---
@app.cli.command("db-init")
def db_init():
    db.create_all()
    print("Database initialized.")

# --- Routes ---
@app.route("/")
def home():
    return render_template("home.html")

@app.route("/features")
def features():
    return render_template("features.html")

@app.route("/about")
def about():
    return render_template("about.html")

@app.route("/contact")
def contact():
    return render_template("contact.html")

@app.route("/signup", methods=["GET", "POST"])
def signup():
    if current_user.is_authenticated:
        return redirect(url_for("dashboard"))
    form = SignupForm()
    if form.validate_on_submit():
        existing = User.query.filter_by(email=form.email.data.lower()).first()
        if existing:
            flash("An account with this email already exists.", "error")
            return redirect(url_for("signup"))
        user = User(email=form.email.data.lower())
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        flash("Account created! Please log in.", "success")
        return redirect(url_for("login"))
    return render_template("auth_signup.html", form=form)

@app.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        return redirect(url_for("dashboard"))
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data.lower()).first()
        if user and user.check_password(form.password.data):
            login_user(user)
            flash("Welcome back!", "success")
            next_url = request.args.get("next")
            return redirect(next_url or url_for("dashboard"))
        flash("Invalid credentials.", "error")
    return render_template("auth_login.html", form=form)

@app.route("/logout")
@login_required
def logout():
    logout_user()
    flash("Logged out.", "success")
    return redirect(url_for("home"))

@app.route("/dashboard")
@login_required
def dashboard():
    q = request.args.get("q", "").strip()
    branch = request.args.get("branch", "").strip()

    query = Student.query.filter_by(user_id=current_user.id)

    if q:
        like = f"%{q}%"
        query = query.filter(
            db.or_(
                Student.roll_number.ilike(like),
                Student.name.ilike(like)
            )
        )
    if branch and branch in BRANCHES:
        query = query.filter_by(branch=branch)

    students = query.order_by(Student.name.asc()).all()
    total_count = Student.query.filter_by(user_id=current_user.id).count()

    return render_template("dashboard.html", students=students, total_count=total_count, q=q, branch=branch, BRANCHES=BRANCHES)

@app.route("/students/create", methods=["GET", "POST"])
@login_required
def student_create():
    form = StudentForm()
    if form.validate_on_submit():
        s = Student(
            roll_number=form.roll_number.data.strip(),
            name=form.name.data.strip(),
            branch=form.branch.data,
            email=form.email.data.strip() if form.email.data else None,
            phone=form.phone.data.strip() if form.phone.data else None,
            user_id=current_user.id
        )
        try:
            db.session.add(s)
            db.session.commit()
            flash("Student added.", "success")
            return redirect(url_for("dashboard"))
        except Exception as e:
            db.session.rollback()
            flash("Error: roll number might already exist.", "error")
    return render_template("student_form.html", form=form, action="Add")

@app.route("/students/<int:student_id>/edit", methods=["GET", "POST"])
@login_required
def student_edit(student_id):
    s = Student.query.filter_by(id=student_id, user_id=current_user.id).first_or_404()
    form = StudentForm(obj=s)
    if form.validate_on_submit():
        s.roll_number = form.roll_number.data.strip()
        s.name = form.name.data.strip()
        s.branch = form.branch.data
        s.email = form.email.data.strip() if form.email.data else None
        s.phone = form.phone.data.strip() if form.phone.data else None
        try:
            db.session.commit()
            flash("Student updated.", "success")
            return redirect(url_for("dashboard"))
        except Exception as e:
            db.session.rollback()
            flash("Error updating student.", "error")
    return render_template("student_form.html", form=form, action="Update")

@app.route("/students/<int:student_id>/delete", methods=["POST"])
@login_required
def student_delete(student_id):
    s = Student.query.filter_by(id=student_id, user_id=current_user.id).first_or_404()
    try:
        db.session.delete(s)
        db.session.commit()
        flash("Student deleted.", "success")
    except Exception:
        db.session.rollback()
        flash("Error deleting student.", "error")
    return redirect(url_for("dashboard"))

@app.errorhandler(404)
def not_found(e):
    return render_template("404.html"), 404

if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(host="0.0.0.0/0",debug=True, port=5000)
