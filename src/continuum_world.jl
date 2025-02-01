@with_kw struct ContinuumWorld <: Environment
    size = [10, 10]                          # dimensions
    terminal_centers = [[4.5,4.5],[6.5,7.5]] # obstacle and goal centers
    terminal_radii = [0.5, 0.5]              # radius of obstacle and goal
    directions = [[0,1],[0,-1],[-1,0],[1,0]] # up, down, left, right
end

(env::ContinuumWorld)(s, a) = env(s, a, rand(Ds(env, s, a)))

function (env::ContinuumWorld)(s, a, x)
    dir = env.directions[a]
    return s .+ dir
end

Ps(env::ContinuumWorld) = Product([Uniform(0,1), Uniform(0,1)])
Ds(env::ContinuumWorld, s, a) = Deterministic()

function load_cw_policy(filename::String)
    res = BSON.load(filename)
    grid = res[:grid]
    Q = res[:Q]
    return grid, Q
end

const Project3LargeSystemOriginal::Type = System{InterpAgent, ContinuumWorld, IdealSensor}

get_depth(sys::Project3LargeSystemOriginal) = get_depth(sys.env)
get_depth(env::ContinuumWorld) = 20
