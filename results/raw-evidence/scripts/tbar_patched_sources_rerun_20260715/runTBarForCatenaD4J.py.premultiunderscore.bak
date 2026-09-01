import os
import re
import shutil
import signal
import subprocess
import platform
import sys
import time

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE)
from gzoltar_analyzer import gzoltar


def run_cmd(cmd_string, timeout=18000):
    print("命令为：" + cmd_string)
    p = subprocess.Popen(cmd_string, stderr=subprocess.STDOUT, stdout=subprocess.PIPE, shell=True, close_fds=True,
                         start_new_session=True)

    format = 'utf-8'
    if platform.system() == "Windows":
        format = 'gbk'

    try:
        (msg, errs) = p.communicate(timeout=timeout)
        ret_code = p.poll()
        if ret_code:
            code = 1
            msg = "[Error]Called Error ： " + str(msg.decode(format))
        else:
            code = 0
            msg = str(msg.decode(format))
    except subprocess.TimeoutExpired:
        # 注意：不能只使用p.kill和p.terminate，无法杀干净所有的子进程，需要使用os.killpg
        p.kill()
        p.terminate()
        os.killpg(p.pid, signal.SIGTERM)

        # 注意：如果开启下面这两行的话，会等到执行完成才报超时错误，但是可以输出执行结果
        # (outs, errs) = p.communicate()
        # print(outs.decode('utf-8'))

        code = 1
        msg = "[ERROR]Timeout Error : Command '" + cmd_string + "' timed out after " + str(timeout) + " seconds"
    except Exception as e:
        code = 1
        msg = "[ERROR]Unknown Error : " + str(e)

    return code, msg


if __name__ == "__main__":
    # Some config
    # start_index = 0
    # end_index = 0
    # tbar_home = '/home/lxy/research/multi_location_bug_repair/TBar4SampleBugs'
    # tbar_project_root = tbar_home + '/D4J/projects'
    # sample_project_file = 'filterOutput.txt'
    # d4j_home = '/home/lxy/research/multi_location_bug_repair/defects4j'
    # log_dir = '/home/lxy/research/multi_location_bug_repair/tbar_log'

    start_index = int(sys.argv[1])
    end_index = int(sys.argv[2])
    tbar_home = sys.argv[3]
    tbar_project_root = tbar_home + '/D4J/projects'
    sample_project_file = sys.argv[4]
    d4j_home = sys.argv[5]
    log_dir = '/tbar_log'
    

    # 1. Get the Project List
    with open(sample_project_file, encoding='utf-8') as sample_projects:
        projects = sample_projects.readlines()
        for i in range(start_index, end_index + 1):
            sample_project = projects[i].replace('\n', '')
            sample_project_ele = sample_project.split("_")
            project_name = sample_project_ele[0]
            bugid_num = sample_project_ele[1]
            cid_num = sample_project_ele[2]
            print(sample_project)
            print(project_name)
            print(bugid_num)
            print(cid_num)
            # 2. checkout project
            write_dir = "{}/{}_{}".format(tbar_project_root, project_name, bugid_num)
            print("write_dir:" + write_dir)
            if os.path.exists(write_dir):
                shutil.rmtree(write_dir)
            print(
                "execute================catena4j checkout -p {} -v {}b{} -w {}".format(project_name, bugid_num, cid_num,
                                                                                       write_dir))
            os.system("catena4j checkout -p {} -v {}b{} -w {}".format(project_name, bugid_num, cid_num, write_dir))

            # 3. change FailedTestCases file in TBar
            result, msg = run_cmd(
                'cd {}/{}_{} && defects4j compile'.format(tbar_project_root, project_name, bugid_num))
            result, failed_test_cases = run_cmd(
                'cd {}/{}_{} && defects4j test'.format(tbar_project_root, project_name, bugid_num))
            os.system('cd {}/{}_{} && git init && git add .'.format(tbar_project_root, project_name, bugid_num))
            with open('{}/FailedTestCases/{}_{}.txt'.format(tbar_home, project_name, bugid_num), 'w') as f:
                failed_test_cases = failed_test_cases[failed_test_cases.index('Failing tests'):]
                f.write(failed_test_cases)

            # 4. change FL result in TBar
            src_ranking_file = "C4J_location/105SampleBugsResult/{}/ochiai.ranking.txt".format(sample_project)
            dst_ranking_file = '{}/SuspiciousCodePositions/{}_{}/Ochiai.txt'.format(tbar_home, project_name, bugid_num)
            if not os.path.exists('{}/SuspiciousCodePositions/{}_{}'.format(tbar_home, project_name, bugid_num)):
                os.mkdir('{}/SuspiciousCodePositions/{}_{}'.format(tbar_home, project_name, bugid_num))
            if not os.path.exists(dst_ranking_file):
                os.system(r'touch {}'.format(dst_ranking_file))
            gzoltar_obj = gzoltar()
            gzoltar_obj.transfer_for_tbar(src_ranking_file, dst_ranking_file)

            # 5. run TBar
            start_time = time.time()
            result, msg = run_cmd(
                'cd {} && ./NormalFLTBarRunner.sh {}/ {} {}/'.format(tbar_home, tbar_project_root,
                                                                     project_name + "_" + bugid_num, d4j_home))
            end_time = time.time()
            if not os.path.exists(log_dir):
                os.mkdir(log_dir)
            with open(log_dir + "/TBar.log", 'a') as f:
                f.write('[Project Info Start]{}====={}====={}s\n[Project Info End]\n'.format(msg, sample_project,
                                                                                             str(end_time - start_time)))

            # 6. change the out dir name
            patch_output_root = tbar_home + "/OUTPUT/NormalFL/TBar"
            output1_dir = "FixedBugs"
            output2_dir = "PartiallyFixedBugs"
            patch_output_dirlist = os.listdir(patch_output_root)
            for pattern_dir in patch_output_dirlist:
                dir1 = os.path.join(patch_output_root, pattern_dir, output1_dir)
                dir2 = os.path.join(patch_output_root, pattern_dir, output2_dir)
                if os.path.exists(dir1) and project_name + "_" + bugid_num in os.listdir(dir1):
                    os.rename(dir1 + "/" + project_name + "_" + bugid_num, dir1 + "/" + sample_project)
                if os.path.exists(dir2) and project_name + "_" + bugid_num in os.listdir(dir2):
                    os.rename(dir2 + "/" + project_name + "_" + bugid_num, dir2 + "/" + sample_project)
